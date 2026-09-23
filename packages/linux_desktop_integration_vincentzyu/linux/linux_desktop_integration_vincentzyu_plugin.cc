#include "include/linux_desktop_integration_vincentzyu/linux_desktop_integration_vincentzyu_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#define LINUX_DESKTOP_INTEGRATION_VINCENTZYU_PLUGIN(obj)                       \
  (G_TYPE_CHECK_INSTANCE_CAST((obj),                                     \
                              linux_desktop_integration_vincentzyu_plugin_get_type(), \
                              LinuxDesktopIntegrationVincentzyuPlugin))

struct _LinuxDesktopIntegrationVincentzyuPlugin {
  GObject parent_instance;
  FlMethodChannel* channel;
  FlView* view;
  gboolean urgency_handler_connected;
};

G_DEFINE_TYPE(LinuxDesktopIntegrationVincentzyuPlugin,
              linux_desktop_integration_vincentzyu_plugin,
              g_object_get_type())

// True while the application runs on the X11 backend of GDK.
static gboolean display_is_x11() {
#ifdef GDK_WINDOWING_X11
  GdkDisplay* display = gdk_display_get_default();
  return display != nullptr && GDK_IS_X11_DISPLAY(display);
#else
  return FALSE;
#endif
}

// Reads the X server timestamp a launcher stored in DESKTOP_STARTUP_ID.
//
// Handing that timestamp back to the window manager is what makes it accept a
// focus request that comes from a background application.
static guint32 startup_timestamp(const gchar* startup_notification_id) {
  if (startup_notification_id == nullptr) {
    return GDK_CURRENT_TIME;
  }
  const gchar* marker = g_strstr_len(startup_notification_id, -1, "_TIME");
  if (marker == nullptr) {
    return GDK_CURRENT_TIME;
  }
  return static_cast<guint32>(g_ascii_strtoull(marker + 5, nullptr, 10));
}

static GtkWindow* toplevel_window(LinuxDesktopIntegrationVincentzyuPlugin* self) {
  if (self->view == nullptr) {
    return nullptr;
  }
  GtkWidget* toplevel = gtk_widget_get_toplevel(GTK_WIDGET(self->view));
  if (toplevel == nullptr || !GTK_IS_WINDOW(toplevel)) {
    return nullptr;
  }
  return GTK_WINDOW(toplevel);
}

// The urgency hint stays set until the window is focused again.
static gboolean on_focus_in(GtkWidget* widget,
                            GdkEventFocus* event,
                            gpointer user_data) {
  (void)event;
  (void)user_data;
  gtk_window_set_urgency_hint(GTK_WINDOW(widget), FALSE);
  return FALSE;
}

static void activate_window(LinuxDesktopIntegrationVincentzyuPlugin* self,
                            FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;
  GtkWindow* window = toplevel_window(self);
  if (window == nullptr) {
    response = FL_METHOD_RESPONSE(fl_method_error_response_new(
        "unavailable", "No application window is available to raise.",
        nullptr));
  } else {
    const gchar* startup_notification_id = nullptr;
    FlValue* args = fl_method_call_get_args(method_call);
    if (args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP) {
      FlValue* value = fl_value_lookup_string(args, "startupNotificationId");
      if (value != nullptr && fl_value_get_type(value) == FL_VALUE_TYPE_STRING) {
        startup_notification_id = fl_value_get_string(value);
      }
    }

    if (!self->urgency_handler_connected) {
      g_signal_connect(window, "focus-in-event", G_CALLBACK(on_focus_in),
                       nullptr);
      self->urgency_handler_connected = TRUE;
    }

    gtk_window_deiconify(window);
    gtk_window_present_with_time(
        window, startup_timestamp(startup_notification_id));
    if (!display_is_x11()) {
      // Wayland does not let a background application move the focus, so the
      // dock entry is asked to draw attention instead.
      gtk_window_set_urgency_hint(window, TRUE);
    }
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  fl_method_call_respond(method_call, response, nullptr);
}

static void minimize_window(LinuxDesktopIntegrationVincentzyuPlugin* self,
                            FlMethodCall* method_call) {
  g_autoptr(FlMethodResponse) response = nullptr;
  GtkWindow* window = toplevel_window(self);
  if (window == nullptr) {
    response = FL_METHOD_RESPONSE(fl_method_error_response_new(
        "unavailable", "No application window is available to minimize.",
        nullptr));
  } else {
    // The compositor makes the final decision under Wayland. GTK still gives
    // every supported desktop a standard minimize request.
    gtk_window_iconify(window);
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_bool(TRUE)));
  }
  fl_method_call_respond(method_call, response, nullptr);
}

static void handle_method_call(FlMethodChannel* channel,
                               FlMethodCall* method_call,
                               gpointer user_data) {
  (void)channel;
  LinuxDesktopIntegrationVincentzyuPlugin* self =
      LINUX_DESKTOP_INTEGRATION_VINCENTZYU_PLUGIN(user_data);
  if (g_strcmp0(fl_method_call_get_name(method_call), "activateWindow") == 0) {
    activate_window(self, method_call);
    return;
  }
  if (g_strcmp0(fl_method_call_get_name(method_call), "minimizeWindow") == 0) {
    minimize_window(self, method_call);
    return;
  }
  g_autoptr(FlMethodResponse) response =
      FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  fl_method_call_respond(method_call, response, nullptr);
}

static void linux_desktop_integration_vincentzyu_plugin_dispose(GObject* object) {
  LinuxDesktopIntegrationVincentzyuPlugin* self =
      LINUX_DESKTOP_INTEGRATION_VINCENTZYU_PLUGIN(object);
  g_clear_object(&self->channel);
  G_OBJECT_CLASS(linux_desktop_integration_vincentzyu_plugin_parent_class)
      ->dispose(object);
}

static void linux_desktop_integration_vincentzyu_plugin_class_init(
    LinuxDesktopIntegrationVincentzyuPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose = linux_desktop_integration_vincentzyu_plugin_dispose;
}

static void linux_desktop_integration_vincentzyu_plugin_init(
    LinuxDesktopIntegrationVincentzyuPlugin* self) {
  (void)self;
}

void linux_desktop_integration_vincentzyu_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  LinuxDesktopIntegrationVincentzyuPlugin* plugin =
      LINUX_DESKTOP_INTEGRATION_VINCENTZYU_PLUGIN(g_object_new(
          linux_desktop_integration_vincentzyu_plugin_get_type(), nullptr));
  plugin->view = fl_plugin_registrar_get_view(registrar);
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  plugin->channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "linux_desktop_integration_vincentzyu/methods", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(plugin->channel, handle_method_call,
                                           plugin, nullptr);
}

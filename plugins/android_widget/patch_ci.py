from pathlib import Path


manifest_path = Path("android/app/src/main/AndroidManifest.xml")
manifest = manifest_path.read_text(encoding="utf-8")

receiver_block = """
        <receiver
            android:name=".DemoAppWidgetProvider"
            android:exported="true">
            <intent-filter>
                <action android:name="android.appwidget.action.APPWIDGET_UPDATE" />
                <action android:name="com.example.dart_flutter_demo.APPWIDGET_TICK" />
            </intent-filter>
            <meta-data
                android:name="android.appwidget.provider"
                android:resource="@xml/demo_widget_info" />
        </receiver>
"""

if "DemoAppWidgetProvider" not in manifest:
    insert_at = manifest.rfind("</application>")
    if insert_at == -1:
        raise RuntimeError("Failed to find </application> in AndroidManifest.xml")
    manifest = manifest[:insert_at] + receiver_block + manifest[insert_at:]

manifest_path.write_text(manifest, encoding="utf-8")

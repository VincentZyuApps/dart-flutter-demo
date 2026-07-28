# Privacy Policy

Last updated: July 28, 2026

This Privacy Policy describes how `dart-flutter-demo` handles information when you use the application. A Simplified Chinese translation is available in [PRIVACY.zh-cn.md](PRIVACY.zh-cn.md).

## Summary

`dart-flutter-demo` has no developer-operated backend, user accounts, advertising, analytics, telemetry, or automatic crash reporting. The developer does not collect or sell personal information through the application.

The application processes device information locally, writes local diagnostic logs, and makes network requests only for features that need public online resources.

## Information Processed Locally

The System Info page may read operating-system and device information such as the OS version, CPU model and processor count, memory, disk space, uptime, boot time, hostname, and local IP address. This information is displayed and processed on your device.

The application writes rotating diagnostic session logs in its application-support directory. These logs may contain device information, including the hostname and local IP address. Each log is limited to 10 MiB, and the application keeps at most five recent log files.

When you select a local font file in Typography Studio, the application reads that file only to render the local preview. It does not upload the selected font file.

## Network Requests And Third Parties

The Adaptive Grid page requests public repository metadata from the GitHub API and may load public avatar images provided by GitHub. GitHub receives the usual network request information, such as your IP address and HTTP request metadata, under the [GitHub Privacy Statement](https://docs.github.com/site-policy/privacy-policies/github-general-privacy-statement).

The application uses the `google_fonts` package and may download font files from Google Fonts when a requested font is not already available locally. Google handles those requests under the [Google Privacy Policy](https://policies.google.com/privacy).

If you enable the optional proxy setting, applicable GitHub requests are routed through the proxy server you specify. The proxy operator may be able to observe those requests, so use only a proxy you trust.

Links opened in an external browser are handled by your browser and the destination website under their respective privacy policies.

## Information Not Collected By The Developer

The application does not automatically upload system information, diagnostic logs, selected local files, hostname, local IP address, or exported files to the developer. It does not include advertising identifiers, tracking SDKs, or a developer-operated analytics service.

## User Choices And Data Removal

Exporting a system-information log requires an explicit confirmation in the application. After export, you control the exported file and where it is shared.

You can remove local application data through the operating system or by uninstalling the application. Files that you exported to another location must be removed separately by you.

## Children's Privacy

The application is a general-purpose software demonstration and is not directed to children. The developer does not knowingly collect personal information from children through the application.

## Changes To This Policy

Material changes will be published in this repository with an updated date at the top of this policy.

## Contact

For privacy questions or requests, open an issue in the [dart-flutter-demo GitHub repository](https://github.com/VincentZyuApps/dart-flutter-demo/issues).

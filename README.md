# yummer

A new Flutter project.

## web debug

The web needs to disable web security if using mealie to avoid CORS issues.

`flutter run -d chrome --web-port=8090 --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=/tmp/chrome_dev"`

## android debug

`flutter run -d device id`

## build apk

update version in pubspec.yaml before building
example: version: 1.0.0+1
`flutter build apk --release`

## publish to play store

```
dart pub add rename
dart run rename setBundleId --value com.jkstreamin.yummer
dart run rename setAppName --value "Yummer"
flutter build appbundle --release
```


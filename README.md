# yummer

A new Flutter project.

## web debug

The web needs to disable web security if using mealie to avoid CORS issues.

`flutter run -d chrome --web-port=8090 --web-browser-flag "--disable-web-security" --web-browser-flag "--user-data-dir=/tmp/chrome_dev"`

## android debug

`flutter run -d device id`

## build apk

`flutter build apk --release`


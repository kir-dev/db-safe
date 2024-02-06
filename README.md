# DB Safe

Egy ruby script ami a docker postgre adatbázisokról csinál automata backup-ot

## Használat (Valszeg csak linuxon fog futni rendesen)

1. `bundle install`
2. `bundle exec ruby db_backup.rb <options>`

### Options

* --dry: Nem végez változtatás, csak ki printeli mit fog csinálni
* --local: Nem tölti fel google drive-ra, csak a főkönyvtárba rakja a zip-et
* --verbose: Logfájl helyett konzolba ír ki dolgokat

### Konténer kihagyása

Ha egy konténerről nem kell beckup, a .dbignore fájlba írd be a nevét egy külön sorba

### Env

A google-höz kell Service Account certificate. A fájl nevét a `CERT_NAME`-be rakd bele.

A cél mappa linkje a `DRIVE_URL`-be menjen bele. Példa a `.env.example`-ben

## Cron job

**TBA**

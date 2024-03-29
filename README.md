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

Az automatikus ütemezéshez a [whenever](https://github.com/javan/whenever) gem-et használja.

A `config/schedule.rb` fájlban lehet új ütemezést felvenni. A crontab frissítésére a `bunlde exec whenever --update-crontab` parancsot kell futtatni 

## Volume safe

Ha teljes volume-okat akarsz menteni, már azt is tud.
Azokat menti automatikusan, amelyeken rajta van a "hu.kidev.dbsafe" címke.
Mivel nem lehet már létező volume-ra újat rakni, azért van egy kis script ami megcsinálja helyetted

`bundle exec ruby ./relabel_volume <volume_name> "hu.kirdev.dbsafe"`

vagy ha ki akarod kapcsolni akkor 

`bundle exec ruby ./relabel_volume <volume_name>`

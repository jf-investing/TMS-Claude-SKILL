---
name: raport
description: Raport wykonanej roboty z firmowego TMS — co komu wyszło z rąk w danym okresie i co zostało w toku, z możliwością zapisania tego do dziennika pracy w dokumentach TMS. Użyj, gdy użytkownik pyta „co dziś zrobione", „podsumuj mi dzień", „podsumuj tydzień", „co zrobiłem od poniedziałku", „co Wojtek zrobił wczoraj", „raport z sierpnia", „co wyszło mi z rąk w tym tygodniu", „co teraz robię", „nad czym siedzę", „co mam w trakcie", albo prosi „zapisz to do dziennika", „dopisz dzisiejszy dzień do dziennika pracy".
---

# Raport wykonanej roboty

Podsumowujesz robotę, która w podanym okresie wyszła komuś z rąk. Wszystko bierzesz
z TMS — raport ma odbijać stan systemu, a nie go upiększać.

## Ustawienia

Te same co przy zadaniach — plik szukany po kolei w `$TMS_CONFIG`,
`~/.tms/config.json` i `~/.claude/tms.json`. W przykładach niżej `$KLUCZ` to
`apiKey`, `$BASE` to `baseUrl`. Brak pliku albo brak klucza → powiedz, że skill nie
jest skonfigurowany, i odeślij do `/tms:ustawienia`.

**Klucza nie wypisujesz** — bierzesz go do zmiennej i tyle. Ani `cat` na tym pliku,
ani podanie go parserowi JSON-a; dlaczego i co zamiast tego, mówi skill `zadanie`,
sekcja „Odczyt ustawień". Stamtąd te dwie linijki:

```bash
CFG=$(for p in "$TMS_CONFIG" ~/.tms/config.json ~/.claude/tms.json; do [ -f "$p" ] && echo "$p" && break; done)
KLUCZ=$(grep -v '^[[:space:]]*//' "$CFG" \
  | grep -o '"apiKey"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//; s/"$//')
BASE=$(grep -v '^[[:space:]]*//' "$CFG" \
  | grep -o '"baseUrl"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*: *"//; s/"$//')
```

## Co się liczy

Pozycją raportu jest zadanie, w którym wskazana osoba jest **wykonawcą** i które
w danym okresie **wyszło jej z rąk** — czyli ma `doneAt` w zakresie. Nic więcej nie
liczysz; wybór robi serwer, Ty podajesz zakres i osobę.

Kotwicą jest moment wyjścia z rąk, nie moment cudzej decyzji. **Zatwierdzenie przez
kogoś innego dwa dni później nie tworzy drugiej pozycji ani nie przesuwa zadania na
inny dzień** — robota oddana w piątek zostaje w piątku, choćby recenzent kliknął
w poniedziałek. Zadanie z `reworked: true` wracało już do poprawy; powiedz o tym w raporcie,
bo bez tego dzień wygląda na obfitszy, niż był.

Robota **w toku** stoi pod kreską, w osobnej sekcji — patrz „Zadania w toku". Nad
kreską nie wchodzi: dzień, w którym coś zaczęto, to nie to samo co dzień, w którym
coś oddano.

Poza raportem zostają **zadania odstawione („Czeka") i nierozpoczęte**. Odstawione
stoi z powodu, którego lista nie pokazuje; nierozpoczęte to pytanie „co mam do
zrobienia", na które odpowiada skill `zadanie`.

## Jak pytasz

Jedno zapytanie na cały okres:

```bash
curl -s -H "Authorization: Bearer $KLUCZ" --get \
  --data-urlencode "doneFrom=2026-08-31" \
  --data-urlencode "doneTo=2026-08-31" \
  --data-urlencode "personId=7" \
  --data-urlencode "limit=300" \
  "$BASE/api/v1/integrations/tasks"
```

Wraca `{"data":{"tasks":[…]}}`. Poza tym, co znasz z zadań (`id` — numer zadania,
`title`, `status`, `statusLabel`, `projectName`; `taskId` to nazwa parametru
zapytania, nie pola w odpowiedzi), każda pozycja niesie trzy pola raportowe:
`doneAt` — moment wyjścia roboty z rąk **tej osoby**, `materialsExcerpt` — początek
jej materiałów do weryfikacji gołym tekstem albo `null`, oraz `reworked`.

### Okres

**Wysyłasz samą datę (`2026-08-31`) — końce doby dopowiada serwer**, w strefie
firmowej, którą podaje słownik (`timezone`). Nie licz przesunięcia sam i nie
doklejaj godziny: zegar twojej maszyny to strefa człowieka, nie firmy, więc
komuś pracującemu spoza Polski wyciąłbyś inny dzień niż reszcie.

Pełny znacznik ISO z przesunięciem serwer nadal przyjmuje, ale nie masz po co go
składać. „Dziś" bierzesz z daty lokalnej człowieka — na pytanie, gdzie kończy
się ta doba, odpowiada już TMS.

Domyślnie „dziś". Poza tym rozumiesz to, co ludzie mówią: „wczoraj", „od
poniedziałku" (od poniedziałku bieżącego tygodnia do teraz), „od 25 sierpnia",
„sierpień" (cały miesiąc), „ostatnie trzy dni". Przy okresie dłuższym niż dzień
powiedz w pierwszym zdaniu, jaki zakres wziąłeś — „od poniedziałku" bywa nie tym
poniedziałkiem, o którym myślał pytający.

### Osoba

Domyślnie właściciel klucza — jego numer to `me.userId` ze słownika, więc `personId`
podajesz zawsze, także przy raporcie o sobie. Kogoś innego rozpoznajesz po tym samym
słowniku:

```bash
curl -s -H "Authorization: Bearer $KLUCZ" "$BASE/api/v1/integrations/dictionary"
```

`personId` to numer osoby z `users`. Lista przychodzi **zawsze**, dla każdego klucza
osobistego — czytanie nazwisk i rozdawanie zadań to dwie różne sprawy, więc
`canAssignToOthers` rządzi wyłącznie zapisem i na raport o cudzej robocie nie ma
wpływu.

Imienia spoza słownika nie dopasowuj na siłę do podobnego i **nie zgaduj numeru**.
Dwa trafienia → pokaż oba i zapytaj, o kogo chodzi. Zero trafień → powiedz wprost,
że takiej osoby w słowniku nie ma.

### Ucięta lista

**Kompletność czytasz z bloku `page`, nie zgadujesz jej z długości listy.**
Odpowiedź niesie go obok `tasks`:

```json
"page": { "total": 359, "limit": 300, "offset": 0, "hasMore": true, "capped": false }
```

- `hasMore` na `false` → masz komplet, nie ostrzegaj przed niczym.
- `hasMore` na `true` → za tą stroną coś jeszcze jest. Znasz `total`, więc powiedz
  wprost, ile: „raport obejmuje 300 z 359 zadań". Resztę dobierz przez `offset`,
  gdy raport ma być pełny.
- `capped` na `true` → zapytanie dobiło do stropu i sam `total` jest ucięty. Tu i
  tylko tu uczciwą odpowiedzią jest „nie wiem, ile tego jest" — napisz to pod
  raportem i zaproponuj węższy okres.

**Nie ostrzegaj przed ucięciem tylko dlatego, że wynik dobił do `limit`.** Przy
`limit=300` komplet 300 zadań wygląda tak samo jak pierwsza strona z 359 — ale
`hasMore` odróżnia jedno od drugiego, więc zgadywanie jest już tylko szkodliwe.
Milczenie zostawia człowieka z raportem, który wygląda na komplet; ostrzeżenie bez
powodu każe mu szukać dziury, której nie ma.

## Jak wygląda raport

Raport ma stały kształt: **nagłówek z datą, a pod nim punktory — linijka na projekt,
nie na zadanie**. W linijce nazwa projektu, myślnik, a po nim to, co w nim wyszło
z rąk.

```
RAPORT z dnia 01.09.2026

- OMS - oferta dostaje w tle dane z Amazona, oferty wyłączone z FBA da się przywrócić
- POCZTA - wysyłanie wiadomości ze szkicu nie działało, naprawione
- TMS - podstawowe narzędzia diagnostyczne wprowadzone na produkcję
```

**Datę w nagłówku piszesz po polsku, z kropkami** — `01.09.2026`, nie `2026-09-01`.
Odwrotnie niż w dzienniku, gdzie zawsze stoi `RRRR-MM-DD`: tam sortuje maszyna, tu
czyta człowiek. Okres dłuższy niż dzień nazywasz zakresem, w tym samym zapisie:
`RAPORT za okres 25.08–01.09.2026`.

Projekt bierzesz z `projectName`. Kolejność linijek: najpierw projekt, w którym
wyszło najwięcej.

**Zadania z `projectName` równym `null` zbierasz w jedną linijkę „Zadania bez
projektu", zawsze ostatnią** — także wtedy, gdy jest ich dużo i dotyczą różnych
rzeczy. Nie wymyślasz im nazwy projektu z tematu: „POCZTA" albo „AROMAHOLIK"
w dzienniku wygląda jak projekt, którego w TMS nie ma, a zadanie nazwane
„OMS | Pakowanie paczek" skleiłoby się z prawdziwym OMS-em, do którego nie należy.

Kosz jest tylko nazwą sekcji, nie zwolnieniem z konkretu. **W środku dalej stoi, co
się zmieniło** — te zadania opisujesz tak samo starannie jak resztę:

```
źle:     Zadania bez projektu - drobne sprawy
dobrze:  Zadania bez projektu - podstrona z kodami UFI, naprawiona wysyłka
                                wiadomości ze szkiców w poczcie
```

Gdy w jednym projekcie wyszły dwie wyraźnie różne rzeczy, **rozbij go na dwie
linijki** z własnymi nazwami — „TMS" i „SKILL TMS" czytają się lepiej niż jedna
linijka o wszystkim naraz. Dzielisz tematem, nie pulą; trzy linijki z jednego
projektu to już siekanie.

**Bez numerów zadań, bez linków, bez godzin.** Nazwę zadania wplatasz tylko wtedy,
gdy sama coś znaczy; poza tym piszesz, co się zmieniło. Kto chce zajrzeć do
konkretnego zadania, poprosi — wtedy podasz numer i link.

### Konkret zamiast etykiety

**Nazwa projektu to nie jest opis roboty.** „OMS — poprawki", „fixy", „prace nad
wtyczką" nie mówią nic i codziennie wyglądają tak samo. Każda linijka ma nazwać,
**co dokładnie** się zmieniło:

```
źle:     OMS - fixy i poprawki
dobrze:  OMS - naprawa wygasającej sesji w panelu, poprawiony skrypt sprzątający po deployach

źle:     TMS - prace nad wtyczką Claude'a
dobrze:  TMS - wtyczka nazywa recenzenta po imieniu i umie go wskazać
```

Miarą jest to, czy po tygodniu da się odróżnić ten dzień od poprzedniego. Nie da się
— linijka jest za ogólna i wracasz po szczegół do `materialsExcerpt`.

**Dwa zdania na projekt wystarczą, ale muszą być szczegółowe.** Krótko nie znaczy
ogólnie: skracasz, wyrzucając wątki poboczne, nie wypłukując treści z tych, które
zostają.

Rzeczy z jednego wątku łącz: osiem wydań wtyczki to nie osiem pozycji, tylko jedna
mówiąca, co wtyczka przez ten dzień dostała — po nazwie każdej z tych rzeczy. Treść
bierzesz z `materialsExcerpt` — to jedyne miejsce, gdzie stoi, co naprawdę zrobione.
Zadanie bez materiałów wchodzi do raportu samą nazwą; niczego nie dopowiadasz.

Wyróżnij to, co czytający musi wiedzieć: co czeka na weryfikację, co wróciło do
poprawy (`reworked`), co jest cudzą decyzją, a nie jego robotą. Reszta ma prawo
zniknąć w zbiorczym zdaniu. Nazwy stanów czytasz ze `status` — `completed`
(zatwierdzone), `to_verify` (czeka na weryfikację), `rework_needed` (wróciło do
poprawy); cokolwiek innego nazywasz `statusLabel` tak, jak przyszło.

Piszesz dla zwykłego człowieka, nie dla programisty. **Nazwy plików, funkcji
i bibliotek zostawiasz w zadaniu** — w raporcie stoi skutek, który widać z zewnątrz.
„Kursy walut pokazywały wczorajszy odczyt, teraz są świeże" zamiast „godzinny cache
w route.ts oddawał przeterminowaną wartość" — ale też **nie** zamiast „poprawka
w WMS". To, czego robota dotyczyła, nazywasz wprost; wycinasz żargon, nie treść.
Materiały bywają pisane technicznie, bo pisał je wykonawca dla siebie; Twoim
zadaniem jest je przetłumaczyć, nie przepisać ani nie wypłukać. Robota, której
skutku nie da się opisać po ludzku, wchodzi do raportu samą nazwą.

Zaczynasz od rzeczy, nie od ramki. „Dzień poszedł prawie w całości na…", „W tym
tygodniu skupiłeś się na…" — takie otwarcia nic nie niosą i brzmią jak wypracowanie.
Dnia nie oceniasz i nie dorabiasz mu narracji: piszesz, co doszło i co się zmieniło.

Długość liczysz projektami, nie zdaniami: **dzień to linijka na każdy projekt,
w którym coś wyszło**, tydzień to samo z grubszym wyliczeniem, miesiąc — akapit na
projekt. Liczby zadań nie podajesz; nikt jej nie potrzebuje, a raport przez nią
wygląda jak rozliczenie.

```
- OMS - domknięte atrybuty amazonowe oferty, adres zdjęcia produktu czeka na weryfikację
- TMS - wtyczka umie zmienić nazwę i priorytet zadania, wrócić z „Czeka",
  rozdzielić niczyje zadania i zrobić raport z zapisem do dziennika
- WMS - kursy walut się odświeżają, poprawione flagi przy wersji angielskiej i mapa
```

Przy okresie dłuższym niż dzień powiedz w pierwszym zdaniu, jaki zakres wziąłeś —
„od poniedziałku" bywa nie tym poniedziałkiem, o którym myślał pytający. Dzień czytasz
z `doneAt` w strefie firmowej ze słownika, nie w swojej — inaczej wieczorna robota
wyląduje w dniu następnym. Dni dziel tylko wtedy, gdy to coś zmienia;
zwykle lepiej czyta się okres opisany jako całość.

### Kilka osób

Pytanie o kilka osób to osobne zapytanie na osobę — `personId` przyjmuje jedną.
**Każda dostaje własne imię, pogrubione i z dwukropkiem**, a pod nim swoje punktory.
Nie mieszaj ludzi w jednej linijce, nawet gdy robili to samo zadanie. Przy raporcie
o jednej osobie imienia nie ma — nagłówek nad własną robotą to zbędny szum.

```
RAPORT z dnia 01.09.2026

**Wojtek:**
- OMS - naprawa wygasającej sesji w panelu, poprawiony skrypt sprzątający po deployach,
  przeglądy PR-ów

**Piotr:**
- OMS - oferta dostaje w tle dane z Amazona, oferty wyłączone z FBA da się przywrócić
- POCZTA - wysyłanie wiadomości ze szkicu nie działało, naprawione
- TMS - wtyczka nazywa recenzenta po imieniu i umie go wskazać
```

Pusty okres kwituj wprost: „W piątek nic nie wyszło Ci z rąk" — bez dorabiania
tłumaczeń, dlaczego tak. Przy kilku osobach człowiek bez domkniętej roboty też
dostaje swoją linijkę; pominięcie go wygląda jak przeoczenie.

Przy raporcie o **cudzej robocie** dołóż zdanie o niepełnym wglądzie — lista jest
przycięta do tego, co widzi właściciel klucza: zadania własne, zlecone przez siebie
i te z projektów, których jest członkiem:

```
To tylko zadania widoczne z Twojego konta — własne, zlecone przez Ciebie
i te z projektów, w których jesteś. Wojtek mógł zrobić więcej.
```

## Zadania w toku

Pod raportem idzie pozioma kreska, a pod nią zadania, przy których człowiek **siedzi
teraz** — status `in_progress` i nic poza tym. To osobne zapytanie, niezależne od
okresu raportu:

```bash
curl -s -H "Authorization: Bearer $KLUCZ" --get \
  --data-urlencode "view=mine_active" \
  --data-urlencode "status=in_progress" \
  --data-urlencode "limit=100" \
  "$BASE/api/v1/integrations/tasks"
```

**`personId` działa wyłącznie razem z `doneFrom`** — każdą inną kombinację serwer
odrzuca komunikatem „personId działa tylko w raporcie". Zadań w toku innej osoby nie
da się więc pobrać; `view=mine_active` z definicji dotyczy właściciela klucza. Przy
raporcie o cudzej robocie sekcji nie ma, a jej brak wyjaśniasz zdaniem:

```
Nad czym Wojtek siedzi teraz, nie widzę — zadania w toku TMS pokazuje tylko
właścicielowi klucza.
```

### Jak wygląda

```
RAPORT z dnia 01.09.2026

- OMS - oferta dostaje w tle dane z Amazona, oferty wyłączone z FBA da się przywrócić
- WMS - kursy walut się odświeżają, poprawione flagi przy wersji angielskiej
- Zadania bez projektu - podstrona z kodami UFI, naprawiona wysyłka ze szkiców w poczcie

───────────────

**W trakcie**
- WMS — miniaturki karteczek olejkowych na sklep niemiecki
- Zadania bez projektu — wtyczka pod pliki feedowe na czeskim sklepie
```

**Ziarno jest inne po obu stronach kreski i to jest celowe.** Nad kreską linijka
przypada na projekt, bo streszczasz tam skutki — osiem wydań wtyczki zlepia się
w jedno zdanie o tym, co wtyczka dostała. Pod kreską linijka przypada na zadanie, bo
„nad czym siedzę" musi dać się wskazać palcem; nazwa projektu idzie z przodu, a
zadanie bez projektu — pod „Zadania bez projektu", tak samo jak nad kreską. Numerów
zadań i linków nie ma po żadnej stronie; kto chce zajrzeć, poprosi.

Przy raporcie o kilku osobach sekcja stoi **raz, na samym dole**, pod wszystkimi
imionami — dotyczy właściciela klucza, więc pod cudze imię nie wchodzi.

Sekcja jest **przy każdym raporcie, niezależnie od okresu**. Przy pytaniu o okres
zamknięty („sierpień") pokazuje stan na dziś, nie na koniec tamtego okresu — stan
„w trakcie" nie ma daty. Dopowiedz to jednym zdaniem, żeby nie wyglądała na część
tamtego miesiąca.

Pustej sekcji nie ma — zamiast niej stoi linijka **„Nic nie masz w trakcie"**. Cisza
w tym miejscu wygląda jak przeoczenie wtyczki, a to co innego niż brak otwartej
roboty.

### Zadania, które wiszą

**Nie ma pola „od kiedy w trakcie".** Zadanie niesie `createdAt` i `dueDate`;
momentu wzięcia się za nie nie niesie żadne. Wiek liczony z `createdAt` jest jedynym
przybliżeniem, jakie masz — i traktujesz go jak przybliżenie: zadanie założone
w lipcu, a wzięte wczoraj, wygląda w nim na wiszące od lipca.

Dlatego zadanie starsze niż **7 dni** nie wchodzi do sekcji po cichu. Zostawiasz je
poza listą i pytasz o nie **pod raportem**, po nazwie i z datą założenia:

```
**W trakcie**
- WMS — miniaturki karteczek olejkowych na sklep niemiecki

Dwa zadania w OMS wiszą od 31 lipca — równoległy odczyt Allegro i pobieranie
zgłoszeń z poczty. Dopisać je do „W trakcie", czy to martwe wątki?
```

Pytanie idzie **po** raporcie, nie przed: raport ma być gotowy od razu, a nie po
odpowiedzi na pytanie o rzeczy poboczne. Odpowiedź dotyczy tego jednego raportu
i nigdzie jej nie zapisujesz — przy następnym pytasz znowu.

## Dziennik

Zapis do dokumentu w TMS robisz **wyłącznie na prośbę** („zapisz to do dziennika") —
nigdy z własnej inicjatywy, choćby raport wyszedł ładny.

Dokument nazywa się `Dziennik pracy — Imię Nazwisko` i **należy do właściciela klucza,
także gdy raport dotyczy kogoś innego** — piszesz do swojego dziennika, nie do
cudzego.

**Imienia i nazwiska do tytułu nie ma w `me`** — jest tam sam `userId` (plus
`canAssignToOthers` i `canCreateProject`). Nazwisko znajdujesz w liście `users`,
dopasowując po `me.userId`, i przepisujesz dokładnie tak, jak przyszło. Lista
przychodzi zawsze, więc dopasowanie powinno być. Gdyby mimo to go nie było,
**zapytaj człowieka, jak ma brzmieć tytuł** — imienia z rozmowy nie bierzesz:
dziennik założy się wtedy pod innym tytułem, a przy następnym raporcie powstanie
drugi dokument zamiast nadpisania tego, który już jest.

Kolejność jest zawsze ta sama: **szukaj po tytule → brak, to załóż → pobierz treść →
złóż nową → zapisz.** Pominięcie odczytu kasuje wszystko, co w dzienniku było.

**Tytuł do szukania też idzie z pliku, nie w argumencie komendy** — tak samo jak
przy zakładaniu:

```bash
printf '%s' 'Dziennik pracy — Jan Kowalski' > tytul.txt
curl -s -H "Authorization: Bearer $KLUCZ" --get \
  --data-urlencode "title@tytul.txt" \
  "$BASE/api/v1/integrations/documents"
```

`printf '%s'`, a nie `echo` ani heredoc: końcowy znak nowej linii dojechałby jako
`%0A` i tytuł przestałby pasować co do znaku.

**Why:** polski napis wpisany w argument programu ginie po drodze. Git Bash na
Windowsie przekodowuje argumenty natywnych programów na CP-1250, zanim curl je
zobaczy: półpauza „—" robi się bajtem `0x97`, „ó" znakiem zastępczym, „ł" cicho
degraduje do „l". Do serwera dochodzi „Dziennik pracy ? Jan Kowalski" i nie ma prawa
się znaleźć. **Skutek jest gorszy niż samo nieznalezienie**: pusta odpowiedź znaczy
tu „dziennika nie ma", więc każdy raport zakłada kolejny dokument o tej samej nazwie
zamiast dopisać do istniejącego. Zmierzone: ten sam tytuł z pliku znajduje dokument,
z argumentu oddaje `null`.

Wraca `{"data":{"document":…}}`, a `null` znaczy, że dziennika jeszcze nie ma.
**Zanim uznasz, że go nie ma, upewnij się, że tytuł poszedł z pliku** — pomylenie
tych dwóch rzeczy mnoży dzienniki.

**Gdy dziennik ma już części, piszesz do najwyższej.** Szukaj od góry: `(część 3)`,
`(część 2)`, na końcu tytuł bez dopisku — i bierz pierwszy, który się znajdzie. Sam
tytuł bez dopisku zawsze istnieje, więc pytany jako pierwszy trafiałby w część
najstarszą i najpełniejszą, czyli dokładnie w tę, od której uciekliśmy. Nową część
zakładasz dopiero wtedy, gdy najwyższa jest pełna (patrz „Limit treści").

Dziennika nie ma w ogóle? Wtedy go zakładasz. Tytuł jest tekstem pisanym dla ludzi,
więc idzie **z pliku**, nie wpisany wprost w komendę (ogonki potrafią dojść jako
krzaki, a odpowiedź i tak wygląda na sukces):

```bash
cat > dziennik.json << 'JSON'
{"title":"Dziennik pracy — Jan Kowalski"}
JSON
curl -s -w '\n%{http_code}' -X POST \
  -H "Authorization: Bearer $KLUCZ" -H "Content-Type: application/json" \
  --data-binary @dziennik.json "$BASE/api/v1/integrations/documents"
```

Odpowiedź niesie `id` i `slug`. Treść czytasz po numerze:

```bash
curl -s -H "Authorization: Bearer $KLUCZ" "$BASE/api/v1/integrations/documents/12"
```

W `{"data":{"document":{…}}}` interesuje Cię `content` — cały dokument jako HTML.

### Kształt sekcji

Sekcja dnia to nagłówek z datą, a pod nim **ten sam tekst co nad kreską
w raporcie** — linijka na projekt, bez numerów zadań i linków. Każdy projekt to
własne `<p>` z nazwą w `<strong>`; list punktowanych nie zakładasz.

**Sekcja „W trakcie" do dziennika nie trafia.** Dziennik jest zapisem dnia, czytanym
miesiącami później — stan chwili wpisany pod datą 31 sierpnia skłamie przy pierwszym
czytaniu w listopadzie, bo zadanie dawno domknięte albo dawno porzucone będzie tam
stało jako trwające.

**W dzienniku data jest zawsze zapisana jako `<h2>RRRR-MM-DD</h2>`** — niezależnie od
tego, że raport dla człowieka mówi „Poniedziałek 31 sierpnia". Data w tym formacie
sortuje się sama i daje się dopasować bez zgadywania.

```html
<h2>2026-08-31</h2>
<p><strong>OMS</strong> — domknięte atrybuty amazonowe oferty, adres zdjęcia produktu czeka na weryfikację.</p>
<p><strong>TMS</strong> — wtyczka umie zmienić nazwę i priorytet zadania, wrócić z „Czeka" i zrobić raport z zapisem do dziennika.</p>
<p><strong>WMS</strong> — kursy walut się odświeżają, poprawione flagi przy wersji angielskiej i mapa.</p>
```

Gdy raport obejmował kilka osób, każda dostaje w sekcji własny blok poprzedzony
`<p><strong>Imię</strong></p>` — tak jak w rozmowie.

**Raport wielodniowy rozbijasz na dni: każdy dzień okresu dostaje własną sekcję**,
osobno dopasowywaną i osobno nadpisywaną. Zapis tygodnia to pięć sekcji, a nie jedna
pod datą początku okresu. Dzień bez zadań pomijasz — pustej sekcji nie zakładasz.

### Kolejność sekcji

**Sekcje stoją datami malejąco, a nową wstawiasz we właściwe miejsce** — nie zawsze na
górę. Gdy w dzienniku są 31 i 25 sierpnia, a dopisujesz 28, ląduje ono **między nimi**.
Na górę trafia tylko dzień świeższy od wszystkiego, co już jest. Raport uzupełniający
za dzień sprzed tygodnia to normalna prośba, nie wyjątek.

### Nadpisywanie

**Jeśli w treści jest już `<h2>` z tą datą, podmieniasz wszystko od tego nagłówka do
następnego `<h2>` (albo do końca dokumentu).** Nie dokładasz drugiej sekcji pod tą
samą datą — dwa wpisy z jednego dnia to dziennik, który kłamie, a człowiek dowie się
o tym miesiąc później, czytając własną notatkę.

Dopasowujesz **po samej dacie w treści nagłówka**, nie po dosłownym `<h2>2026-08-31</h2>`:
nagłówek bywa zapisany z atrybutami, a dziennik mógł powstać wcześniej ręcznie w TMS.
Gdy w dokumencie stoją nagłówki dni w innym formacie (np. „31 sierpnia 2026"),
**powiedz o tym człowiekowi i zapytaj**, zamiast po cichu doklejać obok drugą sekcję
w swoim formacie — inaczej dziennik dostanie dwa wpisy o jednym dniu.

To nie jest wyjątek, tylko normalny bieg rzeczy: ktoś prosi o zapis po południu,
a potem jeszcze raz wieczorem. Za drugim razem dzień ma być **jeden**, ten pełniejszy.
Powiedz o tym jednym zdaniem: „dzisiejsza sekcja nadpisana, pozostałe dni bez zmian".

Zapis nadpisuje **cały** dokument, więc wysyłasz starą treść ze sklejoną nową sekcją.
Też z pliku — to polski tekst:

```bash
cat > tresc.json << 'JSON'
{"content":"<h2>2026-08-31</h2><ul><li>…</li></ul><h2>2026-08-28</h2><ul><li>…</li></ul>"}
JSON
curl -s -w '\n%{http_code}' -X PATCH \
  -H "Authorization: Bearer $KLUCZ" -H "Content-Type: application/json" \
  --data-binary @tresc.json "$BASE/api/v1/integrations/documents/12"
```

Po zapisie powiedz, co doszło, i podaj link do dokumentu (`$BASE/dokumenty/<slug>`).

### Limit treści

Dokument w TMS ma sufit **500 KB**. Progiem, na którym przechodzisz dalej, jest
**450 KB treści** — zmierz ją po złożeniu, przed wysłaniem. Powyżej progu nie dopisuj
na siłę: załóż kolejną część (`Dziennik pracy — Imię Nazwisko (część 2)`, potem
`(część 3)` i tak dalej), zapisz dzień tam i powiedz człowiekowi, że dziennik przeszedł
na następną część.

Odbita `400` przy zapisie znaczy to samo — treść przekroczyła limit w walidacji — ale
to ścieżka awaryjna, nie sposób na poznanie limitu. Załóż wtedy kolejną część zamiast
ponawiać zapis w kółko.

Odmowy:
- `403` — właściciel klucza nie może zakładać dokumentów albo nie jest właścicielem
  tego, do którego piszesz. Powiedz to i nie próbuj obejść innym dokumentem.
- `404` — dokumentu nie ma albo jest poza jego zasięgiem.

## Granice

**Źródłem jest wyłącznie TMS.** Raport nie streszcza rozmowy, nie dolicza roboty,
o której wiesz z tej sesji, i nie dopisuje niczego z pamięci — nawet gdy wiesz, że
człowiek zrobił coś jeszcze. Robota bez zadania w TMS w raporcie nie istnieje; możesz
najwyżej zaproponować założenie zadania (patrz skill `zadanie`).

Nierozpoznane imię kwitujesz pytaniem, nie wyborem najbliższego pasującego. To nie
jest błąd wart tłumaczenia się — po prostu brakuje Ci danych, żeby odpowiedzieć.

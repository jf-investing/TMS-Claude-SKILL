# Skill do Claude — zadania w TMS

## Czym to jest

Dodatek do Claude'a, który po skończonej robocie sam zakłada zadanie w TMS.
Zamiast przepisywać ręcznie co zostało zrobione i co jeszcze trzeba dorobić,
Claude sam składa nazwę, opis, projekt, wykonawcę i priorytet, pokazuje to do
zatwierdzenia i po potwierdzeniu wysyła prosto na produkcję.

Dodatek jest firmowy i wieloosobowy — każdy pracownik ma go u siebie, z własnym
kluczem i własnymi regułami. Zadania zakładają się pod nazwiskiem tej osoby,
która z Claude'a korzysta, a nie pod wspólnym kontem.

## Jak to działa

1. Kończysz robotę z Claude'em.
2. Claude daje krótkie podsumowanie tego, co zrobił.
3. Pod spodem pokazuje gotowe zadanie:

```
Zadanie do TMS

Nazwa:      Poprawić filtr terminów na liście zadań
Opis:       Filtr „ten tydzień" gubi zadania z soboty i niedzieli.
            Zmiana w widoku listy, dotyczy wszystkich użytkowników.
            Do sprawdzenia też w widoku puli.

Projekt:    TMS
Pula:       Zadania / błędy
Wykonawca:  Jan Kowalski
Priorytet:  wysoki
Termin:     —

Założyć? [tak / popraw / anuluj]
```

4. Odpowiadasz `tak`, `popraw` (wtedy mówisz co zmienić) albo `anuluj`.
5. Po `tak` zadanie ląduje w TMS, a Ty dostajesz jego numer i link — żeby od razu
   zobaczyć jak wyszło i ewentualnie poprawić na miejscu.

Zadania założone tą drogą mają w TMS własną ikonkę źródła, tak jak te z Discorda —
od razu widać, że przyszły z rozmowy z Claude'em.

Claude nie zgaduje projektów i osób z pamięci — listę pobiera z TMS na bieżąco,
żeby nie rozjechała się z tym, co faktycznie jest w systemie.

## Zmiana statusu

Poza zakładaniem zadań Claude umie też ruszać te, które już są. Mówisz zwykłym
językiem — „zaczynam 1721", „biorę się za to o filtrach", „oznacz jako zrobione" —
a on znajduje zadanie, pokazuje co znalazł i zmienia status.

Rozpoczęcie pracy dzieje się od razu, bo to odwracalne. Zamknięcie zadania albo
oddanie do weryfikacji zawsze czeka na Twoje „tak".

Przy „zrobione" Claude sam sprawdza, czy zadanie da się zamknąć od ręki. Jeśli
zlecił je ktoś inny albo czeka na recenzenta, zaproponuje oddanie do weryfikacji
zamiast zamknięcia — i powie dlaczego.

Wszystko dzieje się **na Twoich uprawnieniach**: Claude może dokładnie tyle, co
Ty w przeglądarce. Nie ruszy zadania, którego nie widzisz, i nie zamknie takiego,
którego sam nie mógłbyś zamknąć. Zatwierdzania cudzej roboty i odsyłania jej do
poprawy wtyczka nie robi w ogóle — to decyzje recenzenta, podejmowane w TMS.



## Formatowanie opisów

Opis zadania i materiały do weryfikacji trafiają do TMS **sformatowane**, tak jak
gdybyś pisał je ręcznie w edytorze: nagłówki sekcji, listy, pogrubienia, cytaty,
a tam gdzie to ma sens — listy z checkboxami do odhaczania w trakcie roboty.

Claude nie formatuje na siłę. Krótkie zadanie zostaje zwykłym akapitem; sekcje
i listy pojawiają się dopiero wtedy, gdy jest co porządkować — kilka wątków,
ustalenia ze spotkania, rzeczy do zrobienia i te świadomie zostawione na potem.


## Poprawa opisu

Zadanie, które już jest w TMS, można kazać Claude'owi posprzątać — „popraw opis 1766",
„sformatuj to zadanie". Przyda się przy starszych zadaniach, założonych zanim wtyczka
umiała formatować.

Zasada jest jedna: **zmienia się struktura, nie słowa**. Claude rozbije ścianę tekstu na
sekcje i listy, ale nie skróci ani nie przepisze treści, chyba że wyraźnie o to poprosisz.
Pokaże, co się zmieni, zanim wyśle.

Opis zadania to domena osoby, która je zleciła — poprawisz więc zadania własne, a cudze
tylko wtedy, gdy jesteś managerem albo liderem. Jeśli jesteś w zadaniu wykonawcą, Twoim
miejscem są materiały do weryfikacji, nie opis.

## Materiały do weryfikacji

Po skończonej robocie Claude nie zostawia zadania pustego. Gdy zatwierdzisz
propozycję, jednym ciągiem: zakłada zadanie, ustawia je na „W trakcie" i wpisuje
materiały do weryfikacji — co zostało zrobione, a pod tym kroki dla osoby, która
ma to sprawdzić.

Potem się zatrzymuje i pyta, czy oddać. Proponuje właściwe wyjście: „Zakończone",
gdy zadanie jest Twoje i nikt go nie weryfikuje, „Do weryfikacji", gdy czeka na
kogoś — i mówi wtedy, na kogo dokładnie, po imieniu. Możesz też powiedzieć
„jeszcze nie" i zostawić je w trakcie.

Recenzenta da się też wskazać: „niech sprawdzi to Daniel". Claude pokaże skład
przed zmianą i po niej, bo wskazany recenzent dostaje powiadomienie i zadanie
ląduje na jego liście do sprawdzenia. Recenzentem może być tylko ktoś z tego
samego projektu — kogoś z zewnątrz TMS nie przyjmie i Claude powie to wprost,
zamiast podstawiać kogokolwiek podobnego.

Działa też osobno — „dopisz materiały do 1654" uzupełni dowolne zadanie, w którym
jesteś wykonawcą, także takie, które ktoś zlecił Ci wcześniej. Przy zadaniach
wieloosobowych Claude pisze wyłącznie do Twojej części.


## Uprawnienia

Claude pyta TMS o Twoje uprawnienia, **zanim** cokolwiek zaproponuje. Jeśli poprosisz
o zadanie w projekcie, do którego nie masz dostępu, powie to od razu — zamiast układać
propozycję, wysyłać ją i pokazywać Ci odmowę serwera.

Widzisz dokładnie tyle, co w przeglądarce: projekty, w których jesteś, ludzi, których
możesz ustawić wykonawcą, i akcje, na które pozwala Twoja rola.

Sama widoczność projektu to jeszcze nie prawo zakładania w nim zadań — część
projektów tylko się widzi. Claude rozróżnia jedno od drugiego i przy braku
dostępu podaje imię właściciela albo kierownika projektu, żebyś wiedział, kogo
poprosić.

## Zakładanie projektów

Gdy zadanie nie pasuje do niczego, co już jest, możesz kazać Claude'owi założyć nowy
projekt — „załóż projekt Automatyzacja raportów". Pokaże nazwę i opis do zatwierdzenia,
a po Twoim „tak" utworzy go i dopiero w nim założy zadanie.

Właścicielem zostajesz Ty. Jeśli Twoja rola nie pozwala zakładać projektów, Claude
powie to od razu, zamiast próbować.

## Podzadania

Claude widzi checklistę w zadaniu i potrafi ją prowadzić. Przy zakładaniu zadania,
które rozkłada się na kilka wyraźnych kroków, wpisze je jako punkty do odhaczenia
zamiast wyliczenia w opisie — dzięki temu postęp widać na liście zadań.

Gdy bierze się za zadanie, checklistę czyta razem z opisem, z osobnymi opisami
punktów włącznie. Zakres roboty bardzo często stoi właśnie tam, a opis niesie sam
powód — zadanie zrobione po samym opisie bywa zrobione w połowie.

Potem wystarczy powiedzieć „odhacz drugi punkt" albo zapytać „co jeszcze zostało
w 1766". Gdy przy oddawaniu zadania okaże się, że któryś punkt wisi nieodhaczony,
Claude pokaże które i zapyta — sam ich nie odhacza, żeby oddać zadanie.

Punkt, do którego przypięto inne zadanie, zostaje nietknięty — odhacza się sam,
gdy tamto zadanie zostanie zamknięte.

## Komentarze

Komentarze są w TMS główną rozmową o zadaniu — opis mówi, co było do zrobienia na
starcie, a co ustalono po drodze, wiadomo właśnie z nich. Claude je czyta i streszcza:
„co pisali w uwagach do 1721", „czemu to wróciło do poprawy". Zdjęcia wklejone do
komentarza ogląda naprawdę — zrzut z komentarza zwykle niesie sedno sprawy.

Umie też dopisać komentarz i odpowiedzieć na czyjś wpis. Treść zawsze pokazuje przed
wysłaniem i czeka na „tak", bo komentarz widzą wszyscy przy zadaniu i idzie z niego
powiadomienie. Komentujesz pod każdym zadaniem, które widzisz, także cudzym.

Raz napisanego komentarza wtyczka nie poprawia ani nie kasuje — porządki w wątku robi
się w TMS, gdzie widać kontekst.

## Załączniki i zdjęcia

Claude widzi to, co doczepione do zadania: pliki z sekcji zadania i z materiałów do
weryfikacji, a także zdjęcia wklejone prosto do opisu. Otwiera je naprawdę — mówi, co
jest na zrzucie, jaki komunikat błędu widać, co pokazuje wykres. Tak samo czyta PDF-y,
logi, CSV i kod. Worda i Excela nie odczyta i powie to wprost.

W drugą stronę też: plik z dysku — log, zrzut z testu, wygenerowany raport — dołoży do
zadania, po pokazaniu, co i dokąd wysyła. Zrzutu wklejonego do okna rozmowy przekazać
nie może; poprosi o zapisanie go na dysku.

## Blokady

Zadanie potrafi czekać na inne. Gdy pytasz „czemu to stoi" albo „co odblokuje 1721",
Claude powie po ludzku, kto jest po drugiej stronie — na które zadanie się czeka, w
jakim jest stanie i u kogo — z linkiem do tamtego zadania. Pokaże też odwrotnie: kogo
to zadanie samo wstrzymuje.

Blokadę można założyć — „to czeka na 1827". Wisi ona na punkcie checklisty i wskazuje
zadanie, na które ten punkt czeka; po zamknięciu tamtego punkt odhacza się sam.
Przypięcie wysyła powiadomienie, więc zawsze czeka na Twoje „tak".

## Zgłoszenia błędów

Część zadań powstaje ze zgłoszeń — ktoś zgłosił błąd, ktoś zrobił z tego zadanie.
Zgłoszenie żyje własnym życiem i ma autora, który czeka na odpowiedź; zamknięcie
zadania samo z siebie nic z nim nie robi. Claude o tym pamięta: przy zamykaniu zadania
sprawdzi, czy wisi przy nim zgłoszenie, i zaproponuje odpowiedź zgłaszającemu. Sam go
nie zamyka — decyzja jest Twoja.

## Zadanie z pull requesta

„Załóż zadanie z tego PR-a" — Claude bierze tytuł i opis prosto z GitHuba, nie z
pamięci, i składa z tego zwykłą propozycję do zatwierdzenia. Numer PR-a i link
zostają w zadaniu, żeby prowadziło z powrotem do kodu.

## Przegląd tego, co wisi

Bez klikania po tablicy: „co do mnie przyszło" pokaże zadania świeżo na Ciebie
przepisane i te, które wróciły do poprawy. „Co wisi w puli", „na czym stanęliśmy w
projekcie X" — Claude zbierze stan i powie, co zrobione, co w toku, a co czeka i na co.

Umie też pomóc rozdzielić niczyje zadania — pokaże, co leży w puli, z uwzględnieniem
tego, co i tak jest zablokowane, żeby nikt nie brał zadania, którego dziś nie ruszy.

## Podobne zadania

Zanim Claude pokaże propozycję nowego zadania, sprawdza w TMS, czy tego samego
już ktoś nie zgłosił. Jeśli znajdzie coś podobnego — również zamkniętego albo
cudzego — pokaże je i zapyta, czy to ta sama sprawa. Decyzja zawsze należy do
Ciebie; czasem podobne zadanie to celowo osobny temat.

## Raport wykonanej roboty

Zamiast klikać po TMS i przepisywać tytuły, wystarczy zapytać — „co dziś zrobione",
„podsumuj mi ten tydzień", „co Wojtek zrobił wczoraj". Claude zbiera zadania z TMS
i układa je **w linijki po projektach** — bez numerów, linków i godzin:

```
OMS - oferta dostaje w tle dane z Amazona, oferty wyłączone z FBA da się przywrócić
POCZTA - wysyłanie wiadomości ze szkicu nie działało, naprawione
TMS - podstawowe narzędzia diagnostyczne wprowadzone na produkcję
```

Chodzi o to, żeby dało się odróżnić jeden dzień od drugiego. Sama nazwa projektu
opisem roboty nie jest — „OMS: poprawki" i „fixy" codziennie wyglądają tak samo,
więc każda linijka mówi, co dokładnie się zmieniło. Dwa zdania na projekt
wystarczą, byle szczegółowe. Zapytanie o kilka osób rozdziela na bloki pod
imionami. Po numer konkretnego zadania wystarczy poprosić.

Liczy się **wyłącznie robota domknięta** — zadania oddane do weryfikacji albo
zamknięte w podanym okresie. Zadania założone, zaczęte i stojące w toku do raportu
nie wchodzą; raport pokazuje wyniki, a nie sam ruch na tablicy. Zadanie zostaje
w tym dniu, w którym wyszło z rąk, nawet jeśli ktoś zatwierdził je tydzień później.

Raport można też kazać zapisać — „zapisz to do dziennika". Wtedy trafia do dokumentu
„Dziennik pracy — Imię Nazwisko" w module dokumentów TMS, jedna sekcja na dzień,
najnowsze na górze. Powtórna prośba o ten sam dzień nadpisuje sekcję, zamiast
dokładać drugą, więc dziennik nie zaczyna sobie przeczyć.

Raport o cudzej robocie pokazuje tylko to, co widać z Twojego konta — zadania własne,
zlecone przez Ciebie i te z projektów, w których jesteś. Claude mówi o tym wprost,
zamiast udawać komplet.

## Instalacja

### 1. Klucz

W TMS: Ustawienia → Klucze → „Wydaj klucz". Klucz pokazuje się raz — skopiuj go
od razu. Zgubiony odwołujesz i wydajesz nowy, w tym samym miejscu.

### 2. Wtyczka

W rozmowie z Claude'em, dwie komendy:

```
/plugin marketplace add jf-investing/TMS-Claude-SKILL
/plugin install tms@jf-tms
```

Repozytorium jest publiczne, więc instalacja nie wymaga żadnych uprawnień ani
logowania do GitHuba.

Po instalacji wtyczka jest widoczna w „Manage Plugins" — stamtąd idą też
aktualizacje, nie trzeba nic kopiować ręcznie.

### 3. Automatyczne aktualizacje (warto)

Marketplace'y spoza Anthropic mają aktualizacje domyślnie **wyłączone**, więc bez
tego kroku nowe wersje wtyczki trzeba za każdym razem ściągać ręcznie przyciskiem
odświeżania.

W rozmowie z Claude'em napisz `/plugin`, przejdź na zakładkę **Marketplaces**,
wejdź w pozycję **jf-tms** (Enter na niej, nie ikonka odświeżania obok) i wybierz
**Enable auto-update**.


**W okienku „Manage Plugins" w edytorze tej opcji nie ma** — pozycje marketplace'ów
są tam zwykłym tekstem, bez wejścia w szczegóły. Wtedy włącz to w pliku ustawień.
Otwórz `%USERPROFILE%\.claude\settings.json` i przy wpisie `jf-tms` dopisz jedną
linię:

```json
"jf-tms": {
  "source": {
    "source": "git",
    "url": "https://github.com/jf-investing/TMS-Claude-SKILL.git"
  },
  "autoUpdate": true
}
```

Zadziała od następnego uruchomienia Claude'a.

Od tej pory po każdym starcie rozmowy Claude sam sprawdza w tle, czy jest nowsza
wersja. Gdy coś pobierze, dostaniesz powiadomienie z prośbą o `/reload-plugins` —
albo nowa wersja wczyta się przy kolejnym uruchomieniu. Bieżąca rozmowa zawsze
pracuje na tym, co miała w chwili startu, więc nic nie zmieni Ci się w trakcie.

### Aktualizacja jedną komendą (bez klikania)

Zamiast szukać przycisku odświeżania — jedna komenda w terminalu:

```powershell
claude plugin update tms@jf-tms
```

Wymaga zainstalowanego Claude Code jako program w terminalu. Jeśli terminal
odpowiada `claude : The term 'claude' is not recognized`, to znaczy, że masz tylko
rozszerzenie do edytora, a samego programu nie. Doinstalowanie, w PowerShellu:

```powershell
irm https://claude.ai/install.ps1 | iex
```

Instalator kładzie plik w `%USERPROFILE%\.local\bin` i potrafi poprosić o ręczne
dopisanie tego katalogu do PATH. Można to zrobić komendą — wystarczy raz:

```powershell
$bin = "$env:USERPROFILE\.local\bin"
[Environment]::SetEnvironmentVariable("Path", ([Environment]::GetEnvironmentVariable("Path","User").TrimEnd(';') + ";" + $bin), "User")
```

Potem **otwórz nowy terminal** — stary wciąż pamięta poprzedni PATH.

Sama aktualizacja podmienia pliki na dysku, ale rozmowa dalej pracuje na wersji
wczytanej przy starcie. Żeby nowa weszła, zamknij i otwórz edytor i zacznij nową
rozmowę.

### 4. Ustawienia

Wszystko siedzi w jednym pliku. Nowe instalacje zakładaj w `~/.tms/config.json`
(na Windowsie `%USERPROFILE%\.tms\config.json`); stary `~/.claude/tms.json` działa
dalej i nie trzeba go ruszać. Nie ma go jeszcze? Napisz w rozmowie:

```
/tms:ustawienia
```

Claude utworzy plik z opisami wszystkich pól i przeprowadzi przez uzupełnienie.
Ta sama komenda pokazuje później, co masz ustawione i gdzie plik leży.

Plik wygląda tak — każde pole ma nad sobą wyjaśnienie i przykłady:

```json
{
  // Adres firmowego TMS, bez ukośnika na końcu.
  "baseUrl": "https://tms.firma.pl",

  // Klucz osobisty z TMS: Ustawienia → Klucze → „Wydaj klucz".
  "apiKey": "tms_...",

  // true — Claude sam proponuje zadanie po skończonej robocie
  "propose": true,

  // CO wpisywać: domyślny projekt, kogo ustawiać wykonawcą, czego nie proponować
  "rules": "Domyślny projekt: WMS. Zadania dla siebie chyba że mówię inaczej.",

  // JAK to ma brzmieć: długość opisu, ton, czy używać wyliczeń
  "style": "Krótko, bez ozdobników. Opis maksymalnie trzy zdania."
}
```

`rules` mówi **co** wpisać, `style` **jak** to napisać. Oba można zostawić puste.

**Klucz nigdy nie trafia do repo.** Leży tylko u Ciebie i jest Twoją tożsamością —
zadania zakładają się pod Twoim nazwiskiem. Wtyczka nie wypisuje go w rozmowie,
pokazuje najwyżej cztery ostatnie znaki.

Do wydania 0.33.1 włącznie było inaczej: wtyczka odczytywała plik ustawień w całości,
więc klucz lądował w zapisie rozmowy — pliku, który zostaje na dysku po sesji. Jeśli
używałeś którejś ze starszych wersji, **wydaj nowy klucz** (Ustawienia → Klucze),
podmień go w `tms.json`, a stary odwołaj.

### 5. Sprawdzenie

Nowa rozmowa, polecenie `/tms:ustawienia` — powinno pokazać komplet ustawień
bez ostrzeżeń. Potem „załóż w TMS zadanie na próbę": powinien pokazać blok
do zatwierdzenia, a po `tak` — numer i link.

## Inne narzędzia niż Claude

Treść instrukcji nie jest Claude'owa — to zwykłe pliki `SKILL.md` w katalogu
`skills/`, a w nich polska proza i wywołania `curl`. Claude'owe jest samo
opakowanie: marketplace, `/plugin install` i komenda `/tms:ustawienia`. Tam, gdzie
tego nie ma, podpina się to ręcznie i działa tak samo.

**Raz, w dowolnym stałym miejscu:**

```bash
git clone https://github.com/jf-investing/TMS-Claude-SKILL.git ~/.tms/skill
```

**Potem jedna linijka w globalnych instrukcjach Twojego narzędzia** — w pliku, który
czyta ono przy każdej rozmowie (`~/.codex/AGENTS.md`, `~/.gemini/GEMINI.md` i tak
dalej; nazwa zależy od narzędzia):

```
Robota w TMS: przeczytaj ~/.tms/skill/AGENTS.md i trzymaj się tego, co tam stoi.
```

`AGENTS.md` w korzeniu repozytorium jest drogowskazem: mówi, który plik z `skills/`
otworzyć przy jakiej rozmowie, i powtarza trzy zasady, które muszą obowiązywać,
zanim cokolwiek się otworzy — obchodzenie się z kluczem, polska treść przez plik
i link przy numerze zadania. Narzędzia, które same wykrywają skille po
frontmatterze (Claude Code, Copilot CLI), znajdą je również bez tej linijki.

**Konfiguracja** to ten sam plik co u Claude'a, szukany po kolei w trzech miejscach:

1. ścieżka ze zmiennej `TMS_CONFIG`, gdy jest ustawiona,
2. `~/.tms/config.json` — zalecane dla nowych instalacji,
3. `~/.claude/tms.json` — zostaje na stałe, nikt nie musi nic przenosić.

**Aktualizacja:** `git pull` w katalogu klonu. Nie ma tu ani cache'u wtyczek, ani
automatycznego odświeżania, więc bez tego nic się nie zmieni.

Czego poza Claude'em nie ma: komendy `/tms:ustawienia` — ale sam skill ustawień
działa, wystarczy poprosić o ustawienia zwykłym zdaniem — oraz automatycznych
aktualizacji. Zadania założone z innych narzędzi mają w TMS tę samą ikonkę
Claude'a; to świadome uproszczenie, nie przeoczenie.

## Która wersja jest wczytana

Wpisz `/tms:ustawienia` — pierwsza linijka pokaże numer wersji i od razu powie, czy
w repozytorium jest już nowsza.

Numer bierze się z samej wczytanej instrukcji, więc nie da się go pomylić: jeśli
widnieje stary, to znaczy, że stara instrukcja jest aktywna — nawet gdy okno wtyczek
pokazuje już nowszą. Wtedy odśwież źródło w zarządzaniu wtyczkami, **zamknij i otwórz
edytor**, i zacznij nową rozmowę.

Warto mieć włączone automatyczne aktualizacje — bez nich kopia repozytorium nigdy nie
zaciągnie się sama. Ustawienie jest osobne u każdego, w jego pliku `~/.claude/settings.json`:

```json
"extraKnownMarketplaces": {
  "jf-tms": {
    "source": { "source": "git", "url": "https://github.com/jf-investing/TMS-Claude-SKILL.git" },
    "autoUpdate": true
  }
}
```

## Wydawanie nowej wersji

Numer wersji siedzi w czterech miejscach — podbij wszystkie naraz:

1. `.claude-plugin/plugin.json`
2. `.claude-plugin/marketplace.json`
3. `skills/ustawienia/SKILL.md` — sekcja „Wersja" i przykładowy blok pod nią
4. wydanie na GitHubie (`gh release create vX.Y.Z`)

Punkt 3 jest tym, co widzi użytkownik, więc rozjazd z resztą wprowadza w błąd.

Poprawka do już wydanego numeru wymaga **nowego numeru**. Cache wtyczek jest
kluczowany wersją: raz pobrany katalog `<wersja>` nie odświeża się nigdy, więc
zmiana dopchnięta pod starym numerem nie dotrze do nikogo, kto go już ma. Dotyczy
to także poprawki jednej linijki.

## Więcej

Szczegóły ustaleń: [docs/2026-08-19-spec.md](docs/2026-08-19-spec.md)

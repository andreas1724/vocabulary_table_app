import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/vocabulary_controller.dart';
import 'package:vocabulary_table_app/data/controllers/chapter_controller.dart';
import 'package:vocabulary_table_app/data/controllers/vocab_repository.dart';
import 'package:vocabulary_table_app/data/core/di/service_locator.dart';
import 'package:vocabulary_table_app/models/book.dart';
import 'package:vocabulary_table_app/models/chapter.dart';
import 'package:vocabulary_table_app/widgets/vocabulary_table_app.dart';

/* 
rm /Users/user/Library/Containers/com.example.vocabularyTableApp/Data/Documents/vocabularies_local.db
*/

void main() async {
  // Always invoke this first before utilizing framework features
  WidgetsFlutterBinding.ensureInitialized();

  SignalsObserver.instance = null;

  await setUpDependencies();

  runApp(
    MaterialApp(
      home: const VocabularyTableApp(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orangeAccent,
          brightness: Brightness.light,
        ),
      ),
      debugShowCheckedModeBanner: false,
    ),
  );
}

Future<void> setUpDependencies() async {
  await setupDependencies();

  final repository = GetIt.I<VocabRepository>();
  const dummyBookId = 'test-csv-book-id';

  Book? activeBook = await repository.getBookLocally(dummyBookId);

  // If the book does not exist or was corrupted (empty items), purge and re-seed
  if (activeBook == null || activeBook.items.isEmpty) {
    if (activeBook != null) {
      debugPrint('Found empty book shell. Purging existing records...');
      await repository.deleteBook(dummyBookId, hardDelete: true);
    }

    final parsedResult = await repository.parseCsv(rawCsv);

    activeBook = Book(
      metadata: BookMetadata.create(
        id: dummyBookId, // Consider using a UUID package instead of hardcoding in production
        title: parsedResult.title,
        languageA: parsedResult.languageA,
        languageB: parsedResult.languageB,
        commentHeader: parsedResult.commentHeader,
      ),
      items: parsedResult.vocabularyItems,
    );

    await repository.saveBookLocally(activeBook);
    debugPrint('CSV parsed and securely saved to Sembast.');
    final uniqueChapterNames = parsedResult.vocabularyItems
        .map((item) => item.chapterId)
        .toSet()
        .toList();

    for (var i = 0; i < uniqueChapterNames.length; i++) {
      final name = uniqueChapterNames[i];
      final chapter = Chapter.create(
        id: name,
        bookId: dummyBookId,
        name: name,
        order: i,
      );
      await repository.addChapterLocally(chapter);
    }
  } else {
    debugPrint(
      'Loaded existing book from Sembast with ${activeBook.items.length} items.',
    );
  }

  // At this point, activeBook is guaranteed to be non-null and seeded.
  GetIt.I.registerLazySingleton<VocabularyController>(
    () => VocabularyController(repository: repository, book: activeBook!),
  );

  GetIt.I.registerLazySingleton<ChapterController>(
    () => ChapterController(
      repository: repository,
      bookId: activeBook!.metadata.id,
    ),
  );
}

const rawCsv = '''
Vokabelheft zum Testen
Englisch;Deutsch;Kommentar
Fruit
apple;Apfel;süß
banana;Banane;gelb und krumm
orange;Orange;saftig
strawberry;Erdbeere;rot und lecker
grape;Weintraube;wächst an Reben
pineapple;Ananas;tropisch
watermelon;Wassermelone;erfrischend im Sommer
peach;Pfirsich;weiche Schale
lemon;Zitrone;sehr sauer
I like fresh fruit;Ich mag frisches Obst;vollständiger Satz
Building
house;Haus;Wohngebäude
church;Kirche;religiöses Bauwerk
skyscraper;Wolkenkratzer;sehr hoch
apartment;Wohnung;im Mehrfamilienhaus
library;Bibliothek;viele Bücher
hospital;Krankenhaus;medizinische Versorgung
school;Schule;Ort zum Lernen
bridge;Brücke;überquert Flüsse
castle;Burg;historisches Bauwerk
We build a new house;Wir bauen ein neues Haus;vollständiger Satz
Vehicle
car;Auto;vier Räder
bicycle;Fahrrad;zwei Räder
train;Zug;auf Schienen
bus;Bus;öffentlicher Nahverkehr
airplane;Flugzeug;fliegt hoch
motorcycle;Motorrad;schnell unterwegs
subway;U-Bahn;fährt unterirdisch
boat;Boot;auf dem Wasser
truck;Lastwagen;schwerer Transport
The train arrives on time;Der Zug kommt pünktlich an;vollständiger Satz
Animal
dog;Hund;treuer Begleiter
cat;Katze;eigenwilliger Charakter
horse;Pferd;großes Nutztier
cow;Kuh;gibt Milch
sheep;Schaf;weiche Wolle
lion;Löwe;König der Tiere
elephant;Elefant;langer Rüssel
bird;Vogel;kann fliegen
rabbit;Hase;lange Ohren
The brown dog barks loudly;Der braune Hund bellt laut;vollständiger Satz
Food
bread;Brot;frisch gebacken
butter;Butter;aus Milch
cheese;Käse;herzhaft
egg;Ei;vom Huhn
rice;Reis;Hauptnahrungsmittel
pasta;Nudeln;italienische Küche
soup;Suppe;warm serviert
salad;Salat;frisch zubereitet
meat;Fleisch;Proteinquelle
She cooks dinner every evening;Sie kocht jeden Abend Abendessen;vollständiger Satz
Beverage
water;Wasser;lebensnotwendig
milk;Milch;weißes Getränk
coffee;Kaffee;macht morgens wach
tea;Tee;heiß aufgebrüht
juice;Saft;aus Früchten
beer;Bier;beliebtes Kaltgetränk
wine;Wein;aus Trauben
lemonade;Limonade;erfrischend süß
mineral water;Mineralwasser;mit Kohlensäure
Do you want some coffee;Möchtest du etwas Kaffee trinken;vollständiger Satz
Clothing
shirt;Hemd;elegantes Oberteil
trousers;Hose;für die Beine
jacket;Jacke;hält warm
shoes;Schuhe;für die Füße
hat;Hut;Kopfbedeckung
dress;Kleid;einteiliges Kleidungsstück
coat;Mantel;für den Winter
socks;Socken;in den Schuhen
sweater;Pullover;weicher Strick
He wears a warm jacket;Er trägt eine warme Jacke;vollständiger Satz
Body Part
head;Kopf;oberer Körperteil
arm;Arm;zum Greifen
hand;Hand;fünf Finger
leg;Bein;zum Gehen
foot;Fuß;am Beinende
eye;Auge;zum Sehen
ear;Ohr;zum Hören
nose;Nase;zum Riechen
mouth;Mund;zum Sprechen
My left leg hurts today;Mein linkes Bein schmerzt heute;vollständiger Satz
Furniture
table;Tisch;vier Beine
chair;Stuhl;zum Sitzen
bed;Bett;zum Schlafen
sofa;Sofa;bequem im Wohnzimmer
wardrobe;Kleiderschrank;für Kleidung
shelf;Regal;für Bücher
desk;Schreibtisch;zum Arbeiten
lamp;Lampe;spendet Licht
carpet;Teppich;auf dem Boden
The wooden table is heavy;Der Holztisch ist sehr schwer;vollständiger Satz
Family
mother;Mutter;weiblicher Elternteil
father;Vater;männlicher Elternteil
brother;Bruder;männliches Geschwisterteil
sister;Schwester;weibliches Geschwisterteil
son;Sohn;männliches Kind
daughter;Tochter;weibliches Kind
grandfather;Großvater;Opa
grandmother;Großmutter;Oma
uncle;Onkel;Bruder der Eltern
My whole family lives here;Meine ganze Familie lebt hier;vollständiger Satz
Profession
doctor;Arzt;behandelt Kranke
teacher;Lehrer;unterrichtet Schüler
engineer;Ingenieur;technischer Beruf
lawyer;Anwalt;Rechtsberatung
carpenter;Tischler;arbeitet mit Holz
nurse;Krankenschwester;pflegt Patienten
pilot;Pilot;steuert Flugzeuge
cook;Koch;bereitet Speisen zu
police officer;Polizist;sorgt für Sicherheit
The friendly doctor helps patients;Der freundliche Arzt hilft Patienten;vollständiger Satz
Emotion
happy;glücklich;gute Laune
sad;traurig;Niedergeschlagenheit
angry;wütend;großer Zorn
tired;müde;braucht Schlaf
excited;aufgeregt;voller Vorfreude
nervous;nervös;vor einer Prüfung
proud;stolz;auf einen Erfolg
surprised;überrascht;unerwartetes Ereignis
calm;ruhig;völlig entspannt
We are all very happy;Wir sind alle sehr glücklich;vollständiger Satz
Weather
sun;Sonne;hell am Himmel
rain;Regen;Wassertropfen
snow;Schnee;weiß im Winter
wind;Wind;bewegte Luft
cloud;Wolke;am Himmel
storm;Sturm;starker Wind
fog;Nebel;schlechte Sicht
frost;Frost;unter dem Gefrierpunkt
thunder;Donner;nach dem Blitz
The dark clouds bring rain;Die dunklen Wolken bringen Regen;vollständiger Satz
Nature
tree;Baum;Holzstamm und Blätter
flower;Blume;blüht im Frühling
forest;Wald;viele Bäume
mountain;Berg;hohe Erhebung
river;Fluss;fließendes Gewässer
lake;See;stehendes Gewässer
sea;Meer;große Wasserfläche
meadow;Wiese;voller Gras
stone;Stein;hartes Mineral
The green tree grows fast;Der grüne Baum wächst schnell;vollständiger Satz
Technology
computer;Computer;für die Arbeit
keyboard;Tastatur;zum Tippen
screen;Bildschirm;visuelle Anzeige
mouse;Maus;Zeigegerät
smartphone;Smartphone;mobiles Telefon
internet;Internet;weltweites Netzwerk
cable;Kabel;leitet Strom
printer;Drucker;bringt Text aufs Papier
camera;Kamera;macht Fotos
The modern computer works fast;Der moderne Computer arbeitet schnell;vollständiger Satz
Sport
soccer;Fußball;mit dem Ball
swimming;Schwimmen;im Wasser
running;Laufen;Ausdauersport
tennis;Tennis;mit Schläger und Netz
basketball;Basketball;Wurf in den Korb
cycling;Radfahren;Sport auf zwei Rädern
skiing;Skifahren;Sport auf Schnee
volleyball;Volleyball;über das Netz
gymnastics;Turnen;Beweglichkeit und Kraft
They play tennis every Sunday;Sie spielen jeden Sonntag Tennis;vollständiger Satz
Color
red;rot;Signalfarbe
blue;blau;Farbe des Himmels
green;grün;Farbe der Natur
yellow;gelb;Farbe der Sonne
black;schwarz;dunkelste Farbe
white;weiß;hellste Farbe
brown;braun;Farbe der Erde
grey;grau;Mischung aus Schwarz und Weiß
purple;lila;edle Farbe
The bright blue sky shines;Der helle blaue Himmel strahlt;vollständiger Satz
School
book;Buch;gedruckter Text
pen;Stift;zum Schreiben
notebook;Notizheft;für Aufzeichnungen
ruler;Lineal;zum Messen
eraser;Radiergummi;entfernt Bleistift
blackboard;Tafel;im Klassenzimmer
pencil;Bleistift;aus Graphit
schoolbag;Schultasche;für alle Unterlagen
calculator;Taschenrechner;für mathematische Aufgaben
The diligent student reads daily;Der fleißige Schüler liest täglich;vollständiger Satz
Kitchen
knife;Messer;zum Schneiden
fork;Gabel;zum Aufspießen
spoon;Löffel;für flüssige Speisen
plate;Teller;für das Essen
cup;Tasse;für Heißgetränke
pan;Pfanne;zum Braten
pot;Topf;zum Kochen
oven;Ofen;zum Backen
fridge;Kühlschrank;hält Lebensmittel frisch
Clean the dirty dishes now;Spüle das schmutzige Geschirr ab;vollständiger Satz
Time
monday;Montag;erster Arbeitstag
morning;Morgen;Beginn des Tages
evening;Abend;Ende des Tages
night;Nacht;Zeit zum Schlafen
month;Monat;vier Wochen
year;Jahr;zwölf Monate
minute;Minute;sechzig Sekunden
hour;Stunde;sechzig Minuten
weekend;Wochenende;Samstag und Sonntag
Time passes by very fast;Die Zeit vergeht sehr schnell;vollständiger Satz
''';

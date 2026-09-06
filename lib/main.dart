import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:vocabulary_table_app/controller/vocabulary_controller.dart';
import 'package:vocabulary_table_app/data/controllers/vocab_repository.dart';
import 'package:vocabulary_table_app/data/core/di/service_locator.dart';
import 'package:vocabulary_table_app/models/book.dart';
import 'package:vocabulary_table_app/widgets/vocabulary_table_app.dart';

/* 
rm /Users/user/Library/Containers/com.example.vocabularyTableApp/Data/Documents/vocabularies_local.db
*/

void main(List<String> args) async {
  SignalsObserver.instance = null;

  WidgetsFlutterBinding.ensureInitialized();

  await setUpDependencies();

  runApp(
    MaterialApp(
      home: const VocabularyTableApp(),
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orangeAccent,
          brightness: .light,
        ),
      ),
      debugShowCheckedModeBanner: false,
    ),
  );
}

Future<void> setUpDependencies() async {
  // 1. Initialize core services and the repository
  await setupDependencies(); // Aufruf aus service_locator.dart

  final repository = GetIt.I<VocabRepository>();

  const dummyBookId = 'test-csv-book-id';
  Book? book = await repository.getBookLocally(dummyBookId);

  if (book == null || book.items.isEmpty) {
    if (book != null && book.items.isEmpty) {
      debugPrint(
        'Found empty book shell from previous invalid run, re-parsing...',
      );
      await repository.deleteBookLocally(dummyBookId);
    }

    final parsedResult = await repository.parseCsv(rawCsv);

    book = Book(
      metadata: BookMetadata(
        id: dummyBookId,
        title: 'CSV Import Test',
        languageA: parsedResult.languageA,
        languageB: parsedResult.languageB,
        modifiedTime: DateTime.now(),
      ),
      items: parsedResult.vocabularyItems,
    );

    await repository.saveBookLocally(book);
    debugPrint('CSV parsed and securely saved to Sembast.');
  } else {
    debugPrint(
      'Loaded existing book from Sembast with ${book.items.length} items.',
    );
  }

  GetIt.I.registerLazySingleton<VocabularyController>(
    () => VocabularyController(repository: repository, book: book!),
  );
}

const rawCsv = '''
Englisch;Deutsch
apple;Apfel;süß;Fruit
banana;Banane;gelb und krumm
orange;Orange;saftig
strawberry;Erdbeere;rot und lecker
grape;Weintraube;wächst an Reben
pineapple;Ananas;tropisch
watermelon;Wassermelone;erfrischend im Sommer
peach;Pfirsich;weiche Schale
lemon;Zitrone;sehr sauer
I like fresh fruit;Ich mag frisches Obst;vollständiger Satz
house;Haus;Wohngebäude;Building
church;Kirche;religiöses Bauwerk
skyscraper;Wolkenkratzer;sehr hoch
apartment;Wohnung;im Mehrfamilienhaus
library;Bibliothek;viele Bücher
hospital;Krankenhaus;medizinische Versorgung
school;Schule;Ort zum Lernen
bridge;Brücke;überquert Flüsse
castle;Burg;historisches Bauwerk
We build a new house;Wir bauen ein neues Haus;vollständiger Satz
car;Auto;vier Räder;Vehicle
bicycle;Fahrrad;zwei Räder
train;Zug;auf Schienen
bus;Bus;öffentlicher Nahverkehr
airplane;Flugzeug;fliegt hoch
motorcycle;Motorrad;schnell unterwegs
subway;U-Bahn;fährt unterirdisch
boat;Boot;auf dem Wasser
truck;Lastwagen;schwerer Transport
The train arrives on time;Der Zug kommt pünktlich an;vollständiger Satz
dog;Hund;treuer Begleiter;Animal
cat;Katze;eigenwilliger Charakter
horse;Pferd;großes Nutztier
cow;Kuh;gibt Milch
sheep;Schaf;weiche Wolle
lion;Löwe;König der Tiere
elephant;Elefant;langer Rüssel
bird;Vogel;kann fliegen
rabbit;Hase;lange Ohren
The brown dog barks loudly;Der braune Hund bellt laut;vollständiger Satz
bread;Brot;frisch gebacken;Food
butter;Butter;aus Milch
cheese;Käse;herzhaft
egg;Ei;vom Huhn
rice;Reis;Hauptnahrungsmittel
pasta;Nudeln;italienische Küche
soup;Suppe;warm serviert
salad;Salat;frisch zubereitet
meat;Fleisch;Proteinquelle
She cooks dinner every evening;Sie kocht jeden Abend Abendessen;vollständiger Satz
water;Wasser;lebensnotwendig;Beverage
milk;Milch;weißes Getränk
coffee;Kaffee;macht morgens wach
tea;Tee;heiß aufgebrüht
juice;Saft;aus Früchten
beer;Bier;beliebtes Kaltgetränk
wine;Wein;aus Trauben
lemonade;Limonade;erfrischend süß
mineral water;Mineralwasser;mit Kohlensäure
Do you want some coffee;Möchtest du etwas Kaffee trinken;vollständiger Satz
shirt;Hemd;elegantes Oberteil;Clothing
trousers;Hose;für die Beine
jacket;Jacke;hält warm
shoes;Schuhe;für die Füße
hat;Hut;Kopfbedeckung
dress;Kleid;einteiliges Kleidungsstück
coat;Mantel;für den Winter
socks;Socken;in den Schuhen
sweater;Pullover;weicher Strick
He wears a warm jacket;Er trägt eine warme Jacke;vollständiger Satz
head;Kopf;oberer Körperteil;Body Part
arm;Arm;zum Greifen
hand;Hand;fünf Finger
leg;Bein;zum Gehen
foot;Fuß;am Beinende
eye;Auge;zum Sehen
ear;Ohr;zum Hören
nose;Nase;zum Riechen
mouth;Mund;zum Sprechen
My left leg hurts today;Mein linkes Bein schmerzt heute;vollständiger Satz
table;Tisch;vier Beine;Furniture
chair;Stuhl;zum Sitzen
bed;Bett;zum Schlafen
sofa;Sofa;bequem im Wohnzimmer
wardrobe;Kleiderschrank;für Kleidung
shelf;Regal;für Bücher
desk;Schreibtisch;zum Arbeiten
lamp;Lampe;spendet Licht
carpet;Teppich;auf dem Boden
The wooden table is heavy;Der Holztisch ist sehr schwer;vollständiger Satz
mother;Mutter;weiblicher Elternteil;Family
father;Vater;männlicher Elternteil
brother;Bruder;männliches Geschwisterteil
sister;Schwester;weibliches Geschwisterteil
son;Sohn;männliches Kind
daughter;Tochter;weibliches Kind
grandfather;Großvater;Opa
grandmother;Großmutter;Oma
uncle;Onkel;Bruder der Eltern
My whole family lives here;Meine ganze Familie lebt hier;vollständiger Satz
doctor;Arzt;behandelt Kranke;Profession
teacher;Lehrer;unterrichtet Schüler
engineer;Ingenieur;technischer Beruf
lawyer;Anwalt;Rechtsberatung
carpenter;Tischler;arbeitet mit Holz
nurse;Krankenschwester;pflegt Patienten
pilot;Pilot;steuert Flugzeuge
cook;Koch;bereitet Speisen zu
police officer;Polizist;sorgt für Sicherheit
The friendly doctor helps patients;Der freundliche Arzt hilft Patienten;vollständiger Satz
happy;glücklich;gute Laune;Emotion
sad;traurig;Niedergeschlagenheit
angry;wütend;großer Zorn
tired;müde;braucht Schlaf
excited;aufgeregt;voller Vorfreude
nervous;nervös;vor einer Prüfung
proud;stolz;auf einen Erfolg
surprised;überrascht;unerwartetes Ereignis
calm;ruhig;völlig entspannt
We are all very happy;Wir sind alle sehr glücklich;vollständiger Satz
sun;Sonne;hell am Himmel;Weather
rain;Regen;Wassertropfen
snow;Schnee;weiß im Winter
wind;Wind;bewegte Luft
cloud;Wolke;am Himmel
storm;Sturm;starker Wind
fog;Nebel;schlechte Sicht
frost;Frost;unter dem Gefrierpunkt
thunder;Donner;nach dem Blitz
The dark clouds bring rain;Die dunklen Wolken bringen Regen;vollständiger Satz
tree;Baum;Holzstamm und Blätter;Nature
flower;Blume;blüht im Frühling
forest;Wald;viele Bäume
mountain;Berg;hohe Erhebung
river;Fluss;fließendes Gewässer
lake;See;stehendes Gewässer
sea;Meer;große Wasserfläche
meadow;Wiese;voller Gras
stone;Stein;hartes Mineral
The green tree grows fast;Der grüne Baum wächst schnell;vollständiger Satz
computer;Computer;für die Arbeit;Technology
keyboard;Tastatur;zum Tippen
screen;Bildschirm;visuelle Anzeige
mouse;Maus;Zeigegerät
smartphone;Smartphone;mobiles Telefon
internet;Internet;weltweites Netzwerk
cable;Kabel;leitet Strom
printer;Drucker;bringt Text aufs Papier
camera;Kamera;macht Fotos
The modern computer works fast;Der moderne Computer arbeitet schnell;vollständiger Satz
soccer;Fußball;mit dem Ball;Sport
swimming;Schwimmen;im Wasser
running;Laufen;Ausdauersport
tennis;Tennis;mit Schläger und Netz
basketball;Basketball;Wurf in den Korb
cycling;Radfahren;Sport auf zwei Rädern
skiing;Skifahren;Sport auf Schnee
volleyball;Volleyball;über das Netz
gymnastics;Turnen;Beweglichkeit und Kraft
They play tennis every Sunday;Sie spielen jeden Sonntag Tennis;vollständiger Satz
red;rot;Signalfarbe;Color
blue;blau;Farbe des Himmels
green;grün;Farbe der Natur
yellow;gelb;Farbe der Sonne
black;schwarz;dunkelste Farbe
white;weiß;hellste Farbe
brown;braun;Farbe der Erde
grey;grau;Mischung aus Schwarz und Weiß
purple;lila;edle Farbe
The bright blue sky shines;Der helle blaue Himmel strahlt;vollständiger Satz
book;Buch;gedruckter Text;School
pen;Stift;zum Schreiben
notebook;Notizheft;für Aufzeichnungen
ruler;Lineal;zum Messen
eraser;Radiergummi;entfernt Bleistift
blackboard;Tafel;im Klassenzimmer
pencil;Bleistift;aus Graphit
schoolbag;Schultasche;für alle Unterlagen
calculator;Taschenrechner;für mathematische Aufgaben
The diligent student reads daily;Der fleißige Schüler liest täglich;vollständiger Satz
knife;Messer;zum Schneiden;Kitchen
fork;Gabel;zum Aufspießen
spoon;Löffel;für flüssige Speisen
plate;Teller;für das Essen
cup;Tasse;für Heißgetränke
pan;Pfanne;zum Braten
pot;Topf;zum Kochen
oven;Ofen;zum Backen
fridge;Kühlschrank;hält Lebensmittel frisch
Clean the dirty dishes now;Spüle das schmutzige Geschirr ab;vollständiger Satz
monday;Montag;erster Arbeitstag;Time
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

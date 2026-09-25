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

    // Parallelize database inserts to avoid N+1 I/O blocking
    final chapterFutures = <Future<void>>[];

    for (var i = 0; i < uniqueChapterNames.length; i++) {
      final name = uniqueChapterNames[i];
      final chapter = Chapter.create(
        id: name,
        bookId: dummyBookId,
        name: name,
        order: i,
      );
      chapterFutures.add(repository.addChapterLocally(chapter));
    }

    // Await all inserts concurrently
    await Future.wait(chapterFutures);
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
apple;Apfel;süß und knackig
banana;Banane;gelb und krumm
orange;Orange;saftig und reich an Vitamin C
strawberry;Erdbeere;rot und lecker
grape;Weintraube;wächst an Reben
pineapple;Ananas;tropisch und süß-säuerlich
watermelon;Wassermelone;erfrischend im Sommer
peach;Pfirsich;weiche Schale und saftig
lemon;Zitrone;sehr sauer
pear;Birne;süß, saftig und typische Birnenform
cherry;Kirsche;rot, klein und oft paarweise
plum;Pflaume;blau-violett mit weichem Fruchtfleisch
apricot;Aprikose;samtige Schale und goldgelb
nectarine;Nektarine;glatte Schale, ähnlich wie Pfirsich
quince;Quitte;herb, aromatisch und perfekt für Gelee
mirabelle plum;Mirabelle;kleine, süße gelbe Pflaumenart
greengage;Reneklode;grünlich-gelbe Edelpflaume
damson;Zwetschge;längliche Pflaume mit festem Fruchtfleisch
medlar;Mispel;alte Obstsorte, teigig genossen
crab apple;Holzapfel;wilder, kleiner und herber Apfel
raspberry;Himbeere;zarte rote Sammelsteinfrucht
blackberry;Brombeere;dunkelviolett und waldig-herb
blueberry;Blaubeere;dunkelblau und reich an Antioxidantien
bilberry;Heidelbeere;wilde Waldheidelbeere, färbt dunkel
cranberry;Kranbeere;herb-säuerlich, oft zu Fleisch serviert
lingonberry;Preiselbeere;klein, rot und traditionell eingekocht
gooseberry;Stachelbeere;borstig oder glatt, säuerlich
redcurrant;Rote Johannisbeere;straff gesäuerte kleine Rispen
blackcurrant;Schwarze Johannisbeere;aromatisch-herb, Basis für Cassis
white currant;Weiße Johannisbeere;milder als rote Johannisbeeren
elderberry;Holunderbeere;dunkel, nur gekocht genießbar
chokeberry;Aroniabeere;adstringierend, dunkel und vitaminreich
sea buckthorn;Sanddorn;leuchtend orange Zitrone des Nordens
rowanberry;Vogelbeere;bitter-herb, essbar nach Verarbeitung
mulberry;Maulbeere;süße baumwachsende Beere
cloudberry;Moltebeere;skandinavische bernsteinfarbene Spezialität
boysenberry;Boysenbeere;Kreuzung aus Brombeere und Himbeere
loganberry;Loganbeere;aromatische Himbeer-Brombeer-Kreuzung
tayberry;Taybeere;große, längliche schottische Beere
salmonberry;Prachthimbeere;gelb-orangefarbene Waldbeere
thimbleberry;Thimblebeere;sehr weiche Wildbeere Nordamerikas
barberry;Berberitze;kleine, stark saure rote Beere
goji berry;Gojibeere;rote Trockenfrucht, Superfood
acai berry;Açaí-Beere;brasilianische Palmbeere
juneberry;Felsenbirne;heidelbeerähnlich, marzipanartiger Geschmack
buffaloberry;Büffelbeere;winterharte rote Wildbeere
crowberry;Krähenbeere;arktische immergrüne Zwergstrauchbeere
bearberry;Bärentraube;mehlige rote Wildbeere
serviceberry;Kornelkirsche;rote Frucht des Hartriegels, säuerlich
lime;Limette;intensiv grün, herb und sauer
grapefruit;Grapefruit;groß, bitter-süß und rosafarben
mandarin;Mandarine;leicht zu schälen und süß
clementine;Klementine;oft kernlos und sehr kinderfreundlich
tangerine;Tangerine;dunkelorange Zitrusfrucht
satsuma;Satsuma;sehr milde, kernlose Zitrusfrucht
pomelo;Pomelo;riesige Zitrusfrucht mit dicker Schale
kumquat;Kumquat;Zwergorange, samt Schale essbar
calamondin;Calamondin;kleine sauere Bitterorange
bergamot;Bergamotte;aromatisch, verfeinert Earl-Grey-Tee
yuzu;Yuzu;japanische Edelfrucht mit feinem Aroma
sudachi;Sudachi;japanische würzige Würz-Zitrusfrucht
kabosu;Kabosu;saftige grüne Zitrusfrucht aus Japan
finger lime;Fingerlimette;Kaviarlimette mit platzenden Perlen
kaffir lime;Kaffir-Limette;stark runzlige Schale, würzige Blätter
blood orange;Blutorange;dunkelrot pigmentiertes Fruchtfleisch
bitter orange;Bitterorange;Grundlage für englische Orangenmarmelade
citron;Zitronatzitrone;sehr dicke Schale, Basis für Zitronat
sweet lime;Süße Limette;säurearme Limettenvariante
tangelo;Tangelo;Kreuzung aus Mandarine und Grapefruit
cantaloupe;Cantaloupe-Melone;netzartige Schale mit orangem Fleisch
honeydew melon;Honigmelone;gelbe glatte Schale, süßes Fleisch
galia melon;Galia-Melone;aromatische Netzmelone mit grünlichem Fleisch
charentais melon;Charentais-Melone;französische Delikatesse mit Streifen
canary melon;Kanarische Melone;leuchtend gelbe Ovalmelone
horned melon;Kiwano;stachelige Schale mit geleeartigem Fleisch
casaba melon;Kassaba-Melone;runzlige gelbe Spätmelone
santa claus melon;Piel de Sapo;grün-gefleckte haltbare spanische Melone
mango;Mango;Königin der Tropenfrüchte, cremig-süß
papaya;Papaya;lachsfarbenes Fleisch mit schwarzen Kernen
guava;Guave;intensiv duftend mit essbaren Kernen
passion fruit;Passionsfrucht;purpurne Schale mit aromatischem Gelee
maracuja;Maracuja;gelbe saure Variante der Passionsfrucht
kiwi;Kiwi;braune behaarte Schale, grünes Fruchtfleisch
golden kiwi;Gold-Kiwi;glattere Schale und gelbes süßes Fleisch
lychee;Litschi;höckrige Schale mit weißem glasigem Fruchtfleisch
rambutan;Rambutan;haarige Schale, dem Litschi ähnlich
longan;Longan;Drachenauge-Frucht mit brauner Schale
mangosteen;Mangostane;Königin der Früchte, schneeweiße Segmente
durian;Durian;stinkende Stachelfrucht mit cremigem Kern
jackfruit;Jackfrucht;größte Baumfrucht der Welt, faserig
breadfruit;Brotfrucht;stärkereich, wird gekocht verzehrt
starfruit;Sternfrucht;sternförmiger Querschnitt, knackig-säuerlich
dragon fruit;Drachenfrucht;weißes oder rotes Fruchtfleisch mit Mohnpunkten
yellow pitahaya;Gelbe Pitahaya;gelbe Drachenfrucht, sehr süß
pomegranate;Granatapfel;voller rubinroter saftiger Fruchtkerne
fig;Feige;weich, samenreich und honigsüß
date;Dattel;Brot der Wüste, karamellartig süß
persimmon;Kaki;orange Frucht, honigsüß bei Vollreife
sharon fruit;Sharonfrucht;tanninarme Kakivariante ohne Kern
avocado;Avocado;botanisch eine Beere, nussig und cremig
coconut;Kokosnuss;harte Schale, Kokoswasser und weißes Fleisch
tamarind;Tamarinde;süß-saures Fruchtfleisch in braunen Hülsen
cherimoya;Cherimoya;Zimtapfel mit sahnigem Fruchtfleisch
soursop;Stachelanone;Guanábana, säuerlich-erfrischend
sugar apple;Zimtapfel;schuppige Rinde mit süßem Fruchtmark
custard apple;Ochsenherzapfel;cremige Tropenfrucht aus der Annonenfamilie
sapodilla;Breiapfel;schmeckt nach braunem Zucker und Birne
black sapote;Schwarze Sapote;wird auch Schokoladenpudding-Frucht genannt
white sapote;Weiße Sapote;schmeckt sahnig-süß wie Bananenpudding
mamey sapote;Mamey-Sapote;große mittelamerikanische Frucht mit orangefarbenem Fleisch
canistel;Canistel;gelbe Eierfrucht mit mehlig-süßem Fleisch
feijoa;Feijoa;brasilianische Guave mit Eukalyptus-Ananas-Note
jabuticaba;Jabuticaba;wächst direkt am Baumstamm, weinähnlich
tamarillo;Baumtomate;eiförmig, bittersüß bis herzhaft
physalis;Kapstachelbeere;in Lampionhülle, fruchtig-herb
tomatillo;Tomatillo;wichtig für mexikanische Salsa Verde
prickly pear;Kaktusfeige;stachelige Frucht des Feigenkaktus
jujube;Chinesische Dattel;rote runzlige süße Trockenfrucht
salak;Schlangenhautfrucht;geschuppte Schale, knackiges Apfel-Ananas-Aroma
santol;Santol;südostasiatische Frucht mit saurem Fruchtfleisch
langsat;Langsat;traubenähnliche Bündelfrucht mit süß-sauren Segmenten
duku;Duku;dickschaligere Variante der Lansium-Frucht
pulasan;Pulasan;verwandt mit Rambutan, kurzes weiches Stachelkleid
rose apple;Rosenapfel;Glockenfrucht mit rosenduftendem, wässrigem Fleisch
wax apple;Wachsapfel;knackig und durstlöschend in Asien
water apple;Wasserrose;tropische kleine Glockenfrucht
naranjilla;Lulo;südamerikanische Zitrus-Tomaten-Geschmacksbombe
pepino;Melonenbirne;gestreifte Frucht mit Birnen- und Melonengeschmack
bilimbi;Gurkenbaumfrucht;extrem saure tropische Würzfrucht
carambola;Karambole;andere Bezeichnung für die Sternfrucht
wood apple;Holzapfel (Limonia);steinhart mit aromatischem braunem Brei
baobab fruit;Affenbrotbaumfrucht;pulvriges, trockenes, saures Fruchtfleisch
marula;Marulafrucht;Grundstoff für afrikanischen Likör
safou;Afrikanische Pflaume;Butterschmelzende Frucht, wird gekocht
miracle fruit;Wunderbeere;lässt Saurem süß schmecken
monstera fruit;Köstliches Fensterblatt;schmeckt bei Vollreife wie Obstsalat
noni;Noni;indische Maulbeere, herber Käsegeruch
ackee;Ackee;Nationalfrucht Jamaikas, nur reif genießbar
cupuacu;Cupuaçu;verwandt mit Kakao, aromatisches Fruchtmark
bacuri;Bacuri;beliebte Frucht im Amazonas für Eis und Desserts
caja;Cajá;sauer-süße Steinfrucht aus Brasilien
camu camu;Camu-Camu;extrem hoher Vitamin-C-Gehalt
pitomba;Pitomba;orangebrasilianische Wildfrucht
biriba;Biriba;stachelige Schleimfrucht mit Zitronencreme-Note
lucuma;Lucuma;peruanisches Superfood mit Ahornsirup-Geschmack
sweet granadilla;Süße Granadilla;brüchige Schale mit süßem Fruchtschleim
curuba;Bananen-Passionsfrucht;längliche Passionsfrucht mit Orangegeschmack
giant granadilla;Königs-Granadilla;sehr große melonengroße Passionsfrucht
abiu;Abiu;gelbe Tropenfrucht mit karamellartigem Gelee
genipapo;Genipapo;Frucht für Sirup und indigene Körperfarben
imbe;Afrikanische Mangostane;kleine orange Steinfrucht
kei apple;Kei-Apfel;südasiatische dornige Strauchfrucht
mabolo;Samtapfel;rot behaarte Frucht, schmeckt käseartig-süß
madrono;Erdbeerbaumfrucht;warzenförmige rote Beere des Mittelmeerraums
monkey orange;Affenorange;harte Schale mit gelblichem süßem Fruchtfleisch
natal plum;Natalpflaume;rote Sternblumenfrucht aus Südafrika
sea grape;Meertraube;salztolerante Küstenfrucht der Karibik
hog plum;Mombinpflaume;gelbe saftige Tropenfrucht
jambolan;Jambolanapflaume;dunkelviolette adstringierende Frucht
malay apple;Malaiischer Apfel;dunkelrote birnenförmige Tropenfrucht
pitanga;Surinamkirsche;gerippte säuerliche kirschgroße Frucht
grumichama;Brasilianische Kirsche;dunkelviolett mit weißem süßem Fruchtfleisch
cereus fruit;Säulenkaktusfrucht;dornenlose Wüstenfrucht
chayote;Chayote;birnenförmiges Kürbisgewächs, mild-saftig
breadnut;Brotmandel;Frucht mit essbaren nussartigen Kernen
bignay;Bignay;brombeerähnliche Beeren an Rispen
calabash;Kalebassenfrucht;Flaschenkürbisgewächs
coco plum;Kokospflaume;kleine tropische Küstenbeere
governor's plum;Madagaskarpflaume;rotbraune süße Buschfrucht
ice cream bean;Inga-Schote;weiße, zuckrig-wattige Schotenfrucht
korlan;Korlan;wilder Verwandter von Litschi und Longan
kundong;Asam Kundong;kleine leuchtend rote Wildfrucht
ma-keok;Ma-Keok;thailändische Wildfrucht
marang;Marang;weichstachelige Frucht mit cremigem Samenmantel
medinilla;Medinilla-Beere;rosafarbene Zier- und Beerenfrucht
nance;Nance;kleine gelbe Frucht mit intensivem Aroma
oil palm fruit;Ölpalmenfrucht;fettreiche tropische Büschelfrucht
papaw;Pawpaw;nordamerikanische Indianerbanane mit Mango-Geschmack
pequi;Pequi;gelbe Frucht aus dem brasilianischen Cerrado
pili nut;Pili-Nuss-Frucht;Ölhaltiges Fruchtfleisch auf den Philippinen
pindaiba;Pindaíba;brasilianische Wildannone
quararibea;Chupa-Chupa;faseriges orangerotes süßes Fruchtfleisch
rhambeh;Rambai;traubenartige saure Frucht aus Malaysia
saguaroberry;Saguarobeere;rote süße Frucht des Riesenkaktus
salal;Salalbeere;dunkle Beere der nordamerikanischen Ureinwohner
santol red;Roter Santol;dickwandige süß-saure Steinfrucht
shepherd's tree fruit;Hirtenbaumfrucht;afrikanische Wüstenfrucht
silver buffaloberry;Silber-Büffelbeere;strauchige rote herbe Steinfrucht
snowberry;Schneebeere;weißliche Beere, nur begrenzt genießbar
soncoya;Soncoya;braune stachelige Frucht, Verwandte der Cherimoya
spanish lime;Mamoncillo;grüne Schale mit lachsfarbenem Schleim
strawberry guava;Erdbeer-Guave;kleine rote Guave mit Erdbeeraroma
sugar plum;Felsenmispelfrucht;süßliche kleine Wildfrüchte
sweet calabash;Süße Kalebassenfrucht;gelbe duftende Rankfrucht
sycamore fig;Maulbeerfeige;alte orientalische Feigenart
tallowberry;Wachsmyrtenbeere;aromatische wachsüberzogene Beere
velvet tamarind;Samttamarinde;schwarze Schale mit süßem mehligen Fruchtfleisch
wabiyo;Wabiyo;australische Wildfrucht
water berry;Wasserbeere;afrikanische Syzygium-Frucht
white mulberry;Weiße Maulbeere;honigsüß, ohne Säure
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

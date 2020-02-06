import 'package:converternow/ConversionPage.dart';
import 'package:converternow/Localization.dart';
import 'package:converternow/ReorderPage.dart';
import 'package:converternow/Utils.dart';
import 'package:converternow/main.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import "dart:convert";
import 'UnitsData.dart';
import 'UtilsConversion.dart';
import 'AppManager.dart';

bool isCurrencyLoading=true;
double appBarSize;
Map jsonSearch;
const MAX_CONVERSION_UNITS=19;
class ConversionManager extends StatefulWidget{

  final Function openDrawer;
  final int startPage;
  final Function changeToPage;
  final List<String> listaTitoli;
  final bool showRateSnackBar;

  ConversionManager(this.openDrawer, this.startPage, this.changeToPage, this.listaTitoli, this.showRateSnackBar);

  @override
  _ConversionManager createState() => new _ConversionManager();

}

class _ConversionManager extends State<ConversionManager>{

  
  //@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  var currencyValues={"CAD":1.4487,"HKD":8.6923,"RUB":70.5328,"PHP":56.731,"DKK":7.4707,"NZD":1.7482,"CNY":7.8366,"AUD":1.6245,"RON":4.7559,"SEK":10.7503,"IDR":15536.21,"INR":78.4355,"BRL":4.4158,"USD":1.1087,"ILS":3.9187,"JPY":120.69,"THB":33.488,"CHF":1.1047,"CZK":25.48,"MYR":4.641,"TRY":6.3479,"MXN":21.1244,"NOK":10.2105,"HUF":328.16,"ZAR":16.1202,"SGD":1.5104,"GBP":0.86328,"KRW":1297.1,"PLN":4.2715}; //base euro (aggiornato a 29/10/2019)
  static String lastUpdateCurrency="Last update: 2019-10-29";
  static List listaConversioni;
  static List orderLunghezza=[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15];
  static List orderSuperficie=[0,1,2,3,4,5,6,7,8,9,10];
  static List orderVolume=[0,1,2,3,4,5,6,7,8,9,10,11,12,13];
  static List orderTempo=[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14];
  static List orderTemperatura=[0,1,2,3,4,5,6];
  static List orderVelocita=[0,1,2,3,4];
  static List orderPrefissi=[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20];
  static List orderMassa=[0,1,2,3,4,5,6,7,8,9,10];
  static List orderPressione=[0,1,2,3,4,5];
  static List orderEnergia=[0,1,2,3];
  static List orderAngoli=[0,1,2,3];
  static List orderValute=[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29];
  static List orderScarpe=[0,1,2,3,4,5,6,7,8,9];
  static List orderDati=[0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26];
  static List orderPotenza=[0,1,2,3,4,5,6];
  static List orderForza=[0,1,2,3,4];
  static List orderTorque=[0,1,2,3,4];
  static List orderConsumo=[0,1,2,3];
  static List orderBasi=[0,1,2,3];
  //@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  static List listaOrder=[orderLunghezza,orderSuperficie, orderVolume,orderTempo,orderTemperatura,orderVelocita,orderPrefissi,orderMassa,orderPressione,orderEnergia,
  orderAngoli, orderValute, orderScarpe, orderDati, orderPotenza, orderForza, orderTorque, orderConsumo, orderBasi];
  //@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  final SearchDelegate _searchDelegate=CustomSearchDelegate();
  final GlobalKey<ScaffoldState> scaffoldKey =GlobalKey();

  @override
  void initState() {
    currentPage=widget.startPage;
    _getOrders();
    Future.delayed(Duration.zero, () {
      _getCurrency();
    });
        
    if(widget.showRateSnackBar){
      Future.delayed(const Duration(seconds: 5), () {
        _showReviewSnackBar();
      });
    }
    super.initState();  
  }


  _leggiCurrenciesSalvate(){
    String currencyRead=prefs.getString("currencyRates");
    if(currencyRead!=null){
      CurrencyJSONObject currencyObject = new CurrencyJSONObject.fromJson(json.decode(currencyRead));
      currencyValues=currencyObject.rates;

      String lastUpdateRead=currencyObject.date;
      if(lastUpdateRead!=null)
        lastUpdateCurrency=MyLocalizations.of(context).trans('ultimo_update_valute')+lastUpdateRead;
    }
  }

  _getCurrency() async {
    //SharedPreferences prefs = await SharedPreferences.getInstance();
    String now = DateFormat("yyyy-MM-dd").format(DateTime.now());
   
    String dataFetched=prefs.getString("currencyRates");
    if(dataFetched==null || CurrencyJSONObject.fromJson(json.decode(dataFetched)).date!=now){//se non ho mai aggiornato oppure se non aggiorno la lista da piú di un giorno allora aggiorno
        try{
          final response =await http.get('https://api.exchangeratesapi.io/latest?symbols=USD,GBP,INR,CNY,JPY,CHF,SEK,RUB,CAD,KRW,BRL,HKD,AUD,NZD,MXN,SGD,NOK,TRY,ZAR,DKK,PLN,THB,MYR,HUF,CZK,ILS,IDR,PHP,RON');
          if (response.statusCode == 200) { //if successful

            CurrencyJSONObject currencyObject = new CurrencyJSONObject.fromJson(json.decode(response.body));
            currencyValues=currencyObject.rates;  

            //se tutte le richieste vanno a buon fine aggiorna la data di ultimo aggiornamento
            lastUpdateCurrency=MyLocalizations.of(context).trans('ultimo_update_valute')+MyLocalizations.of(context).trans('oggi');

            //salva in memoria
            prefs.setString("currencyRates", response.body);
          }
          else    //se ho un'errore nella lettura dati dal web (per es non sono connesso)
            _leggiCurrenciesSalvate();//leggi ultimi dati salvati

        }catch(e){//se ho un'errore di comunicazione
          print(e);
          _leggiCurrenciesSalvate(); //leggi ultimi dati salvati
      }
    }
    else{         //se ho già i dati alavati di oggi perchè sono già entrato la prima volta nell'app
      _leggiCurrenciesSalvate();
      lastUpdateCurrency=MyLocalizations.of(context).trans('ultimo_update_valute')+MyLocalizations.of(context).trans('oggi');
    }
    setState(() {
      isCurrencyLoading=false;
    });
  }

  _onSelectItem(int index) {
    if(currentPage!=index) {
      listaConversioni[currentPage].clearSelectedNode();
      widget.changeToPage(index);
    }
  }

  _getJsonSearch(BuildContext context) async {
    jsonSearch ??= json.decode(await DefaultAssetBundle.of(context).loadString("resources/lang/${Localizations.localeOf(context).languageCode}.json"));
  }

  _saveOrders() async {
    //SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> toConvertList=new List();
    for(int item in listaOrder[currentPage])
      toConvertList.add(item.toString());
    prefs.setStringList("conversion_$currentPage", toConvertList);
  }
  _getOrders() async {

    List <String> stringList;
    //aggiorno ordine unità di ogni grandezza fisica
    for(int i=0;i<MAX_CONVERSION_UNITS;i++){
      stringList=prefs.getStringList("conversion_$i");

      if(stringList!=null){
        final int len=stringList.length;
        List intList=new List();
        for(int j=0;j<len;j++){
          intList.add(int.parse(stringList[j]));
        }
        //risolve il problema di aggiunta di unità dopo un aggiornamento
        for(int j=len; j<listaOrder[i].length;j++)     
          intList.add(j);
        
        if(i==currentPage){
          setState(() {
            listaOrder[i]=intList;
          });
        }
        else
          listaOrder[i]=intList;
      }
    }
  }

  _changeOrderUnita(BuildContext context,String title, List listaStringhe) async{
    final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ReorderPage(
            title: title,
            listaElementi: listaStringhe,
        ),));
    List arrayCopia=new List(listaOrder[currentPage].length);
    for(int i=0;i<listaOrder[currentPage].length;i++)
      arrayCopia[i]=listaOrder[currentPage][i];
    setState(() {
      for(int i=0;i<listaOrder[currentPage].length;i++)
        listaOrder[currentPage][i]=result.indexOf(arrayCopia[i]);
    });
    _saveOrders();
  }

  _showReviewSnackBar(){

    final SnackBar positiveResponseSnackBar = SnackBar(
      duration: const Duration(milliseconds: 4000),
      behavior: SnackBarBehavior.floating,
      content: Text(MyLocalizations.of(context).trans('valuta_app3'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.0)),
      action: SnackBarAction(
        label: MyLocalizations.of(context).trans('valuta_app5'),
        textColor: Theme.of(context).accentColor,
        onPressed: (){
          prefs.setBool("stop_request_rating", true);
          launchURL("https://play.google.com/store/apps/details?id=com.ferrarid.converterpro");
        },
      ),
    );

    final SnackBar negativeResponseSnackBar = SnackBar(
      duration: const Duration(milliseconds: 3000),
      behavior: SnackBarBehavior.floating,
      content: Text(MyLocalizations.of(context).trans('valuta_app4'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.0)),
      action: SnackBarAction(
        label: MyLocalizations.of(context).trans('valuta_app5'),
        textColor: Theme.of(context).accentColor,
        onPressed: (){
          prefs.setBool("stop_request_rating", true);
          launchURL("https://play.google.com/store/apps/details?id=com.ferrarid.converterpro");
        },
      ),
    );

    final SnackBar reviewSnackBar = SnackBar(
      duration: const Duration(seconds: 5),
      behavior: SnackBarBehavior.floating,
      content: SizedBox(
        height: 65.0,
        child: Center(
          child: Column(
            children: <Widget>[
              Text(MyLocalizations.of(context).trans('valuta_app2'), style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.0),),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  FlatButton(
                    child: Text(MyLocalizations.of(context).trans('valuta_app2NO'), style: TextStyle(color: Theme.of(context).accentColor),),
                    onPressed: (){
                      scaffoldKey.currentState.hideCurrentSnackBar();
                      scaffoldKey.currentState.showSnackBar(negativeResponseSnackBar);
                    },
                  ),
                  FlatButton(
                    child: Text(MyLocalizations.of(context).trans('valuta_app2SI'), style: TextStyle(color: Theme.of(context).accentColor),),
                    onPressed: (){
                      scaffoldKey.currentState.hideCurrentSnackBar();
                      scaffoldKey.currentState.showSnackBar(positiveResponseSnackBar);
                    },
                  ),
                ]
              )
            ],
          ),
        ),
      ),
    );
    scaffoldKey.currentState.showSnackBar(reviewSnackBar);
  }

  @override
  Widget build(BuildContext context) {
    _getJsonSearch(context);

    listaConversioni=initializeUnits(context, listaOrder, currencyValues);  

    List<Choice> choices = <Choice>[
      Choice(title: MyLocalizations.of(context).trans('riordina'), icon: Icons.reorder),
    ];
    
    return Scaffold(
      key:scaffoldKey,
      resizeToAvoidBottomInset: false,
      body: SafeArea(child:ConversionPage(listaConversioni[currentPage],widget.listaTitoli[currentPage], currentPage==11 ? lastUpdateCurrency : "", MediaQuery.of(context))),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Theme.of(context).primaryColor,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            new Builder(builder: (context) {
              return IconButton(icon: Icon(Icons.menu,color: Colors.white,), onPressed: () {
                widget.openDrawer();
              });
            }),
            Row(children: <Widget>[
              IconButton(
                icon: Icon(Icons.clear,color: Colors.white),
                onPressed: () {
                  setState(() {
                    listaConversioni[currentPage].clearAllValues();
                  });
                },),
              IconButton(
                icon: Icon(Icons.search, color: Colors.white),
                onPressed: () async {
                  final int paginaReindirizzamento=await showSearch(context: context,delegate: _searchDelegate);
                  if(paginaReindirizzamento!=null)
                    _onSelectItem(paginaReindirizzamento);
                },
              ),
              PopupMenuButton<Choice>(
                icon: Icon(Icons.more_vert,color: Colors.white,),
                onSelected: (Choice choice){
                  _changeOrderUnita(context, MyLocalizations.of(context).trans('mio_ordinamento'), listaConversioni[currentPage].getStringOrderedNodiFiglio());
                },
                itemBuilder: (BuildContext context) {
                  return choices.map((Choice choice) {
                    return PopupMenuItem<Choice>(
                      value: choice,
                      child: Text(choice.title),
                    );
                  }).toList();
                },
              ),
            ],)
          ],
        ),
      ),
      
      floatingActionButton: FloatingActionButton(
        child: Image.asset("resources/images/calculator.png",width: 30.0,),
        onPressed: (){
          showModalBottomSheet<void>(context: context,
            builder: (BuildContext context) {
              double displayWidth=MediaQuery.of(context).size.width;
              return Calculator(Theme.of(context).accentColor, displayWidth); 
            }
          );
        },
        elevation: 5.0,
        backgroundColor: Theme.of(context).accentColor,//Color(0xff2196f3)//listaColori[currentPage],
      )
    );
  }
}


class Choice {
  const Choice({this.title, this.icon});

  final String title;
  final IconData icon;
}


class CustomSearchDelegate extends SearchDelegate<int> {  

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
        final List<SearchUnit> _dataSearch=initializeSearchUnits((int pageNumber){close(context,pageNumber);}, jsonSearch);
        final List<SearchGridTile> allConversions=initializeGridSearch((int pageNumber) {close(context, pageNumber);}, jsonSearch, MediaQuery.of(context).platformBrightness==Brightness.dark);

        final Iterable<SearchUnit> suggestions = _dataSearch.where((searchUnit) => searchUnit.unitName.toLowerCase().contains(query.toLowerCase())); //.toLowercase per essere case insesitive
        
        return query.isNotEmpty ? SuggestionList(
          suggestions: suggestions.toList(),
          darkMode: MediaQuery.of(context).platformBrightness==Brightness.dark,
        )
        : GridView(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200.0),
          children: allConversions,
          
        );
      }
    
      @override
      Widget buildResults(BuildContext context) {
        return Container();
      }
    
      @override
      List<Widget> buildActions(BuildContext context) {
        return <Widget>[
          if(query.isNotEmpty)
            IconButton(
              tooltip: 'Clear',
              icon: const Icon(Icons.clear),
              onPressed: () {
                query = '';
                showSuggestions(context);
              },
            ),
        ];
      }
}

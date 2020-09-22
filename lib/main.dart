import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

import './widgets/transaction_list.dart';
import './widgets/new_transaction.dart';
import './models/transaction.dart';
import './widgets/chart.dart';

void main() {
  // WidgetsFlutterBinding.ensureInitialized();//This need to be initialized so that the Orientation lock works
  // SystemChrome.setPreferredOrientations([ //This is to make sure the app only works in Potrait Mode
  //   DeviceOrientation.portraitUp,
  //   DeviceOrientation.portraitDown,
  // ]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Platform.isIOS
        ? CupertinoApp(
            title: 'Personal Expenses',
            home: MyHomePage(),
            theme:
                CupertinoThemeData(// very limited capabilities as of right now
                    ),
          )
        : MaterialApp(
            title: 'Personal Expenses',
            home: MyHomePage(),
            theme: ThemeData(
              errorColor: Colors.redAccent[300],
              primarySwatch: Colors.red,
              accentColor: Colors.amber,
              fontFamily: 'OpenSans',
            ),
          );
  }
}

class MyHomePage extends StatefulWidget {
  // String titleInput;
  // String amountInput;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  /*with is used as an mix in which basically inherits only certain things from a class, 
  the Widgets Binding obserevr is used to determin the lifecycle of the app */
  final List<Transaction> _userTransactions = [];
  bool _showChart = false;
  
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);//Sets ups an listeners and calls didChangeAppLifecycleState 
    super.initState();
  }


  @override //This method is called when lifecycle of the app changes.
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print(state);
  }
  @override //This is to remove the listeners added by the WidgetsBindingObserver widget
  dispose() {
    WidgetsBinding.instance.removeObserver(this);//This clears the appcycle listeners that were created.
    super.dispose();
  }

  List<Transaction> get _recentTransactions {
    return _userTransactions.where((tx) {
      return tx.date.isAfter(
        DateTime.now().subtract(
          Duration(days: 7),
        ),
      );
    }).toList();
  }

  void _addNewTransaction(
      String txTitle, double txAmount, DateTime chosenDate) {
    final newTx = Transaction(
      title: txTitle,
      amount: txAmount,
      date: chosenDate,
      id: DateTime.now().toString(),
    );
    setState(() {
      _userTransactions.add(newTx);
      print(_userTransactions);
    });
  }

  void _startAddNewTransaction(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled:
          true, //This has been added to make it adjust for the keyboard height
      builder: (_) {
        return SingleChildScrollView(
          child: Container(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom),
            child: NewTransaction(_addNewTransaction),
          ),
        );
      },
    );
  }

  void _deleteTransactions(String id) {
    setState(() {
      _userTransactions.removeWhere((element) {
        return element.id == id;
      });
    });
  }

  List<Widget> _buildLandscapeContent(
      MediaQueryData mediaQuery, AppBar appBar, Widget txListWidget) {
    return [
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            'Show Chart',
            style: Theme.of(context).textTheme.headline6,
          ),
          Switch.adaptive(
            //.adaptive is used to make it different for different OS(Andriod/iOS)
            activeColor: Theme.of(context)
                .accentColor, //Use my already accentCOlor for when the switch for the IOS.
            value: _showChart,
            onChanged: (val) {
              setState(() {
                _showChart = val;
              });
            },
          ),
        ],
      ),
      _showChart //Logic so that the chart is only shown if _showChart is true or not
          ? Container(
              height: (mediaQuery.size.height -
                      appBar.preferredSize.height -
                      mediaQuery.padding.top) *
                  0.7,
              child: Chart(_recentTransactions),
            ) //Conditions so that the Show Chart button is only in Landscape mode and not in Protrait mode

          : txListWidget
    ];
  }

  List<Widget> _buildPotraitContent(
      MediaQueryData mediaQuery, AppBar appBar, Widget txListWidget) {
    return [
      Container(
        height: (mediaQuery.size.height -
                appBar.preferredSize.height -
                mediaQuery.padding.top) *
            0.3,
        child: Chart(_recentTransactions),
      ),
      txListWidget
    ];
  }

  Widget _buildAppBar() {
    return Platform //PreferredSizeWidget is used because dart cannot find out the type correctly.
            .isIOS
        ? CupertinoNavigationBar(
            middle: Text(
              'My Flutter App',
            ),
            trailing: Row(
              mainAxisSize:
                  MainAxisSize.min, //Only as big as its children need to be
              children: <Widget>[
                GestureDetector(
                  child: Icon(CupertinoIcons.add),
                  onTap: () => _startAddNewTransaction(context),
                )
              ],
            ),
          )
        : AppBar(
            title: Text(
              'My Flutter App',
            ),
            actions: <Widget>[
              IconButton(
                icon: Icon(
                  Icons.add_circle,
                ),
                onPressed: () => _startAddNewTransaction(context),
              )
            ],
          );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final PreferredSizeWidget appBar = _buildAppBar();
    //This next Varible is only exists so that we dont have to chnage this part multiple times as we call it in different scenarios
    final txListWidget = Container(
      height: (mediaQuery.size.height -
              appBar.preferredSize.height -
              mediaQuery.padding.top) *
          0.7,
      child: TransactionList(_userTransactions, _deleteTransactions),
    );
    final pageBody = SafeArea(
      //Makes sure that the reserved space if left out in iOS devices.
      child: SingleChildScrollView(
        child: Column(
          // mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (isLandscape)
              ..._buildLandscapeContent(
                mediaQuery,
                appBar,
                txListWidget,
              ) //Logic if only we are in Landscape Mode
            ,
            if (!isLandscape)
              ..._buildPotraitContent(
                //... is the spread operator used to extract out elements of a list individually as independent objects
                mediaQuery,
                appBar,
                txListWidget,
              )
            //Conditions so that the Show Chart button is only in Landscape mode and not in Protrait mode
            ,
          ],
        ),
      ),
    );

    return Platform.isIOS
        ? CupertinoPageScaffold(
            child: pageBody,
            navigationBar: appBar,
          )
        : Scaffold(
            appBar: appBar,
            body: pageBody,
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: Platform
                    .isIOS //Came from dart.io, would be used to check if platform is ios
                ? Container()
                : FloatingActionButton(
                    onPressed: () => _startAddNewTransaction(context),
                    child: Icon(
                      Icons.add,
                    ),
                  ),
          );
  }
}

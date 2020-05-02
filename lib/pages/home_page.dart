import 'dart:convert';

import 'package:Ever/models/Events.dart';
import 'package:Ever/models/acara.dart';
import 'package:flutter/material.dart';
import 'package:Ever/services/authentication.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:Ever/template/colors.dart';
import 'package:Ever/template/eventCard.dart';
import 'package:Ever/template/eventDetailBottomSheet.dart';
import 'package:Ever/template/profileBottomSheet.dart';
import 'package:Ever/template/donationBottomSheet.dart';
import 'dart:async';
import 'package:http/http.dart' as http;

bool _eventCardIsUp = false;

class HomePage extends StatefulWidget {
  HomePage({Key key, this.auth, this.userId, this.logoutCallback})
      : super(key: key);

  final BaseAuth auth;
  final VoidCallback logoutCallback;
  final String userId;

  @override
  State<StatefulWidget> createState() => new _HomePageState();
}

class _HomePageState extends State<HomePage> {
  signOut() async {
    try {
      await widget.auth.signOut();
      widget.logoutCallback();
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Stack(
            children: <Widget>[
              Container(
                height: 120.0,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            InkWell(
                              child: Text(
                                'EVER',
                                style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    color: _eventCardIsUp
                                        ? darkBackgroundColor
                                        : Colors.white,
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            InkWell(
                              child: Text(
                                'Log Out',
                                style: TextStyle(
                                    fontFamily: 'Montserrat',
                                    fontSize: 18.0,
                                    color: _eventCardIsUp
                                        ? darkBackgroundColor
                                        : Colors.white),
                              ),
                              onTap: () {
                                signOut();
                              },
                            ),
                            // IconButton(
                            //   icon: Icon(Icons.power_settings_new),
                            //   onPressed: () {
                            //     signOut();
                            //   },
                            // ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(20.0),
                      bottomRight: Radius.circular(20.0)),
                  color: _eventCardIsUp ? Colors.white : darkBackgroundColor,
                ),
              ),
            ],
          ),
          Expanded(child: home()),
        ],
      ),
    );
  }
}

class home extends StatefulWidget {
  @override
  _homeState createState() => _homeState();
}

class _homeState extends State<home> {
  List<Acara> _acaraList;
  Query _acaraQuery;

  final FirebaseDatabase _db = FirebaseDatabase.instance;

  StreamSubscription<Event> _onAcaraAddedSubscription;

  List<Events> _events = List<Events>();

  @override
  void initState() {
    _acaraList = new List();
    _acaraQuery = _db.reference().child("event").orderByChild("eventID");
    _onAcaraAddedSubscription = _acaraQuery.onChildAdded.listen(onEntryAdded);

    fetchEvents().then((value) {
      print('Fetching Data');
      setState(() {
        _events.addAll(value);
      });
    });
    super.initState();
  }

  onEntryAdded(Event acara) {
    setState(() {
      _acaraList.add(Acara.fromSnapshot(acara.snapshot));
    });
  }

  Future<List<Events>> fetchEvents() async {
    var url =
        'https://raw.githubusercontent.com/KevinYobeth/kevinyobeth.github.io/master/Ever/event.json';
    var response = await http.get(url);

    var events = List<Events>();

    if (response.statusCode == 200) {
      var eventsJson = json.decode(response.body);
      for (var eventJson in eventsJson['event']) {
        events.add(Events.fromJson(eventJson));
      }
    }
    return events;
  }

  @override
  void didUpdateWidget(home oldWidget) {
    if (_events.isEmpty || _events.isNotEmpty) {
      fetchEvents().then((value) {
        print('Fetching Data');
        setState(() {
          _events.addAll(value);
        });
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    Widget _showAcaraList() {
      if (_acaraList.length > 0) {
        print('Length > 0 ${_acaraList.length}');
        print(_acaraList[0].eventName);
        return ListView.builder(
          physics: BouncingScrollPhysics(),
          shrinkWrap: false,
          itemCount: _acaraList.length,
          itemBuilder: (BuildContext context, int index) {
            String eventName = _acaraList[index].eventName;
            String eventThumb = _acaraList[index].eventThumb;
            bool isNonProfit = _acaraList[index].isNonProfit;
            return FlatButton(
              child: eventCard(
                eventName: eventName,
                isNonProfit: isNonProfit,
                eventThumb: eventThumb,
              ),
              onPressed: () {
                eventDetailBottomSheet(
                  context,
                  eventName: eventName,
                  isNonProfit: isNonProfit,
                  eventThumb: eventThumb,
                  eventDate: 'Rabu, 18 Maret 2020',
                  eventPlace: 'Indonesia Convention Exhibition Center BSD',
                  eventDesc:
                      "Calling for volunteers! Let's become part of our team to support this charity concert. Your participation "
                      "means a lot for those people in need. Don't miss the chance to have fun with us at #BiggestCharityVibes2020 ",
                  criteria: 'Gender: Male / Female \nAge: 18 - 35 years old',
                  division:
                      'Documentation \nLogistic \nLiaison Officer \nTicketing \nPublic Relation',
                  benefits:
                      'E-certificate \nT-shirt \nGoodie Bag \nFree Ticket',
                  bankAccount: '123456789',
                  bankAccountName: 'Mesyella',
                );
              },
            );
          },
        );
      } else {
        print('Length < 0');
      }
    }

    return Scaffold(
      backgroundColor: white,
      body: Container(
        child: Column(
          children: <Widget>[
            Expanded(
              child: _showAcaraList(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.person),
        backgroundColor: darkBackgroundColor,
        onPressed: () {
          profileBottomSheet(context);
        },
      ),
    );
  }
}

import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 
import 'package:smr/src/theme/theme.dart' as tema;
import 'package:smr/src/widgets/background.dart';
import 'package:wakelock/wakelock.dart';
import '../../chart.dart';

class MedicionPage extends StatefulWidget {
  static final routeName = "medicionPage";
  @override
  MedicionPageView createState() {
    return MedicionPageView();
  }
}

class MedicionPageView extends State<MedicionPage>
    with SingleTickerProviderStateMixin {
 
  int? _selectedIndex;

  bool _toggled = false; //
  List<SensorValue> _data = []; // Arreglo para almacenar las muestras
  CameraController? _controller;
  AnimationController? _animationController;
  double _iconScale = 1;
  int _fs = 30; // frecuencia de muestreo (fps)
  int _windowLen = 30 * 6; // Numero de muestras del arreglo
  CameraImage? _image; // store the last camera image
  double? _avg; // store the average value during calculation
  DateTime? _now; // store the now Datetime
  Timer? _timer; // timer for image processing
  List<int> _bpmList = <int>[];
  int _bpmFinal = 0;
  double? _prom;

  //final firestoreInstance = FirebaseFirestore.instance;
 

  TextStyle styleText = TextStyle(
    fontSize: 21.2,
    color: Colors.black,
  );

  @override
  void initState() {
    //bloc.cargarContactos();
    //bloc.cargarUsuario();
    super.initState();
    _animationController =
        AnimationController(duration: Duration(milliseconds: 500), vsync: this);
    _animationController!
      ..addListener(() {
        setState(() {
          _iconScale = 1.0 + _animationController!.value * 0.4;
        });
      });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _toggled = false;
    _disposeController();
    Wakelock.disable();
    _animationController?.stop();
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
             
            children: [
                tema.gradientBackGround,
                _contenido(context),
            ],
        ),
      ),
    );
  }

  Column _contenido(BuildContext context) {
    return Column( 
        
        children: <Widget>[ 
          SizedBox(height: 30.0,),
          Text("Iniciar medicion", style: tema.styleText_2.copyWith(fontSize: 30) ),
          Expanded(
            flex: 1,
            child: Center(
              child: Transform.scale(
                scale: _iconScale,
                child: IconButton(
                  icon:
                      Icon(_toggled ? Icons.favorite : Icons.favorite_border),
                  color: Colors.red,
                  iconSize: 100,
                  onPressed: () {
                    if (_toggled) {
                      _untoggle();
                    } else {
                      _toggle();
                    }
                  },
                ),
              ),
            ),
          ),
          Container( 
            
            height: MediaQuery.of(context).size.height * 0.15,
            width: MediaQuery.of(context).size.width * 0.75,
            margin: EdgeInsets.all(12),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(
                  Radius.circular(18),
                ),
                border: Border.all(color: Colors.black),
                color: Colors.white38),
            child: Chart(_data),
          ),
          Expanded(
              flex: 1,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    flex: 1,
                    child: Center(
                        child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          "Ritmo estimado",
                          style: tema.styleText_2.copyWith(fontWeight: FontWeight.bold,color: Colors.red),
                        ),
                        Text(
                          (_bpmFinal > 30 && _bpmFinal < 150
                              ? _bpmFinal.toString() + " BPM"
                              : "--"),
                          style: TextStyle(
                              fontSize: 32, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          //color: Colors.greenAccent,
                          onPressed: () {
                            if (_bpmFinal > 0) {
                              _preguntar(context);
                            } else {
                              // utils.mostrarAlerta(context,
                              //     "No hay registro que guardar", "Alerta");
                            }
                          },
                          child: Text("GUARDAR REGISTRO"),
                        ),
                        TextButton(
                          //color: Colors.redAccent,
                          onPressed: () => _preguntar2(context),
                          child: Text("ENVIAR ALERTA"),
                        ),
                      ],
                    )),
                  ),
                ],
              )),
        ],
      );
  }

  void _clearData() {
    _data.clear();
    int now = DateTime.now().millisecondsSinceEpoch;
    for (int i = 0; i < _windowLen; i++) {
      _data.insert(
          0,
          SensorValue(
              DateTime.fromMillisecondsSinceEpoch(now - i * 1000 ~/ _fs), 0));
    }
  }

  void _toggle() {
    _clearData();
    _initController().then((onValue) {
      Wakelock.enable();
      _animationController?.repeat(reverse: true);
      setState(() {
        _toggled = true;
      });
      // after is toggled
      Future.delayed(Duration(seconds: 3)).then((value) {
        _initTimer();
        _updateBPM();
      });
    });
  }

  void _untoggle() {
    _disposeController();
    Wakelock.disable();
    _animationController?.stop();
    _animationController?.value = 0.0;
    setState(() {
      _toggled = false;
    });
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
  }

  Future<void> _initController() async {
    try {
      List _cameras = await availableCameras();
      _controller = CameraController(_cameras.first, ResolutionPreset.low);
      await _controller!.initialize();
      Future.delayed(Duration(milliseconds: 200)).then((onValue) async {
        _controller!.setFlashMode(FlashMode.torch);
      });
      _controller!.startImageStream((CameraImage image) {
        _image = image;
      });
    } catch (exception) {
      debugPrint(exception.toString());
    }
  }

  void _initTimer() {
    _timer = Timer.periodic(Duration(milliseconds: 1000 ~/ _fs), (timer) {
      if (_toggled) {
        if (_image != null) _scanImage(_image!);
      } else {
        timer.cancel();
      }
    });
  }

  void _scanImage(CameraImage image) {
    _now = DateTime.now();
    _avg =
        image.planes.first.bytes.reduce((value, element) => value + element) /
            image.planes.first.bytes.length;

    if (_data.length >= _windowLen) {
      _data.removeAt(0);
    }

    setState(() {
      _data.add(SensorValue(_now!, _avg!));
    });
  }

  void _updateBPM() async {
    SensorValue? max;
    List<int> listbpm = [];
    List<SensorValue> _values = [];
    List<SensorValue> _pulsos = [];
    int bpm;

    while (_toggled) {
      max = null;
      _prom = 0;
      _values = _data;
      _pulsos.clear();

      for (int i = 1; i < 7; i++) {
        max = _valorMaximo((i * 20), (i * 20) + 20, _values);
        _pulsos.add(max);
      }

      if (_pulsos[0].value > 0) {
        for (int i = 1; i < _pulsos.length; i++) {
          bpm = _calcularBPM(_pulsos[i - 1], _pulsos[i]);
          if (bpm > 0) listbpm.add(bpm);
        }

        listbpm.forEach((element) {
          _bpmList.add(element);
        });

        listbpm.clear();

        if (_bpmList.length > 10) {
          //print("LISTA " + _bpmList.toString());
          _prom = 0;
          _bpmList.forEach((element) {
            _prom = _prom! + element / _bpmList.length;
          });
          setState(() {
            _bpmFinal = _prom!.toInt();
            _bpmList.clear();
            _untoggle();
          });
        }
      }

      await Future.delayed(Duration(milliseconds: 200 * _windowLen ~/ _fs));
    }
  }

  SensorValue _valorMaximo(int inicio, int fin, List<SensorValue> list) {
    SensorValue max = SensorValue(_now!, 0);

    for (int i = inicio; i < fin; i++) {
      if (list[i].value > max.value) max = list[i];
    }
    return max;
  }

  int _calcularBPM(SensorValue s1, SensorValue s2) {
    int diferencia =
        s2.time.millisecondsSinceEpoch - s1.time.millisecondsSinceEpoch;
    if (diferencia > 1200 || diferencia < 300) {
      return 0;
    } else {
      return (60000 ~/ diferencia);
    }
  }

  void _preguntar(BuildContext c) {
    showDialog(
      context: c,
      builder: (BuildContext context) => AlertDialog(
        title: Text("Save"),
        content: Text("Desea guardar el presente registro?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(), child: Text("No")),
          TextButton(
              child: Text("Sí"),
              onPressed: () async {
                Navigator.of(context).pop();
                //_guardarRegistro().whenComplete(() {
                //  //utils.mostrarAlerta(c, "Se ha guardado el registro", "Aviso");
                //});
                Future.delayed(Duration(seconds: 2));
                Navigator.of(c).pop();
              }),
        ],
      ),
    );
  }

  Future<void> _preguntar2(BuildContext context) async {
    return showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text("Seleccione uno de sus contactos"),
                content: Text('Hola'),//_listaContactos(context, setState),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("CANCELAR")),
                  TextButton(
                    child: Text("SELECCIONAR"),
                    onPressed: () async {
                      var resp;

                      await showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text("CONFIRMACION"),
                              content:
                                  Text("Enviar mensaje a fulano?"),
                              actions: [
                                TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: Text("NO")),
                                TextButton(
                                  onPressed: () async {
                                    String msg = "Hola " +
                                        //_contacto.name +
                                        ", te informamos que " +
                                        //bloc.user.name +
                                        " " +
                                        //bloc.user.lastname +
                                        " tiene problemas de salud y necesita tu ayuda." +
                                        "Comunicate al: ";

                                    //resp = await _mensajeProvider.enviarSms(
                                    //    _contacto.phoneNumber.toString(), msg);
                                    //Navigator.of(context).pop();
                                    //utils.mostrarAlerta(
                                    //    context, resp.toString(), "RESULTADO");
                                  },
                                  child: Text("SÍ"),
                                ),
                              ],
                            );
                          });
                    },
                  )
                ],
              );
            },
          );
        });
  }

  Future<void> _preguntarEstado(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return AlertDialog(
              content: ListView(
                children: [],
              ),
            );
          },
        );
      },
    );
  }

  Widget _crearEstado(String estado) {
    return ListTile(
      key: UniqueKey(),
      title: Text(estado),
    );
  }

  //Widget _listaContactos(BuildContext context, Function setState) {
  //  return FutureBuilder(
  //      future: _contactoProvider.cargarContactos(_prefs.idUser),
  //      builder: (context, AsyncSnapshot<List<ContactModel>> snapshot) {
  //        if (snapshot.hasData) {
  //          final lista = snapshot.data;
  //          return Container(
  //            height: 300.0,
  //            width: 300.0,
  //            child: ListView.builder(
  //                itemCount: lista.length,
  //                scrollDirection: Axis.vertical,
  //                itemBuilder: (context, index) {
  //                  return ListTile(
  //                    key: UniqueKey(),
  //                    selected: index == _selectedIndex,
  //                    tileColor:
  //                        index == _selectedIndex ? Colors.greenAccent : null,
  //                    trailing: _selectedIndex == index
  //                        ? Icon(Icons.check_box)
  //                        : Icon(Icons.check_box_outline_blank),
  //                    title: Text(lista[index].name),
  //                    subtitle: Text(lista[index].phoneNumber.toString()),
  //                    onTap: () {
  //                      if (_selectedIndex != index) {
  //                        setState(() {
  //                          _selectedIndex = index;
  //                          _contacto = lista[index];
  //                        });
  //                      }
  //                    },
  //                  );
  //                }),
  //          );
  //        }
//
  //        return Center(
  //          child: CircularProgressIndicator(),
  //        );
  //      });
  //}

  //Widget _crearItem(BuildContext context, ContactModel contacto, int index) {
  //  return ListTile(
  //    key: UniqueKey(),
  //    hoverColor: Colors.black,
  //    tileColor: index == _selectedIndex ? Colors.greenAccent : null,
  //    title: Text(contacto.name),
  //    subtitle: Text(contacto.phoneNumber.toString()),
  //    onTap: () {
  //      setState(() {
  //        _selectedIndex = index;
  //      });
  //    },
  //  );
  //}

  //Future<DocumentReference> _guardarRegistro() async {
  //  DateTime date = DateTime.now();
  //  var formatter = new DateFormat("yyyy-MM-dd");
  //  String formattedDate = formatter.format(date);
//
  //  RegistroModel reg = new RegistroModel();
  //  RegistroProvider rp = RegistroProvider();
//
  //  reg.fecha = formattedDate;
  //  reg.bpm = _bpmFinal;
//
  //  if (_bpmFinal > 150) {
  //    reg.alerta = "Alerta máxima";
  //  } else {
  //    if (_bpmFinal <= 150 && _bpmFinal > 100) {
  //      reg.alerta = "Alerta media";
  //    } else {
  //      reg.alerta = "Normal";
  //    }
  //  }
//
  //  var res = await rp.agregarRegistro(_prefs.idUser, reg);
  //  print(res.toString());
//
  //  return res;
  //}
}

// ignore_for_file: unused_element, sort_child_properties_last, use_build_context_synchronously, unused_local_varia ble, unused_local_variable
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:horizontal_data_table/horizontal_data_table.dart';
import 'package:intl/intl.dart';
import 'package:jaztea/models/datoslogin.dart';
import 'package:jaztea/models/datosmapsmanual.dart';
import 'package:jaztea/models/datosvisitas.dart';
import 'package:jaztea/models/datosvendedor.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

class TablaUsuarios {
  final int manual;
  final int automatico;
  int get total {
    return manual + automatico;
  }

  TablaUsuarios({required this.manual, required this.automatico});
}

class SimpleTablePage extends StatefulWidget {
  final String username;
  final Userdata userdata;

  const SimpleTablePage({
    Key? key,
    required this.username,
    required this.userdata,
  }) : super(key: key);

  @override
  State<SimpleTablePage> createState() => _SimpleTablePageState();
}

class _SimpleTablePageState extends State<SimpleTablePage> {
  late VendedoresSupervisor usuarios;
  List<Lista> usuarioname = [];
  DateTime selectedDate = DateTime.now();
  int totalVentas = 0;

  bool isDisposed = false;
  bool isLoading = false;
  int autocount = 0;
  int manualcount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showProcesoMensaje();
    });
  }

  void _showProcesoMensaje() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Proceso en curso'),
          content: const Text(
              'Este proceso tardará un poco. Por favor, no salgas de la pantalla hasta que termine.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el primer AlertDialog
                _showFechaSeleccionadaMensaje(); // Mostrar el segundo AlertDialog
              },
              child: const Text('Aceptar'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.yellow,
              ),
            ),
          ],
          backgroundColor: Colors.yellow,
        );
      },
    );
  }

  void _showFechaSeleccionadaMensaje() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('FECHA REQUERIDA'),
          content: const Text(
              'Selecciona una fecha en el icono de la parte de arriba.'),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _selectDate(
                    context); // Llama a la función _selectDate después de cerrar el AlertDialog
              },
              child: const Text('Aceptar'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.yellow,
              ),
            ),
          ],
          backgroundColor: Colors.yellow,
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    if (isDisposed) return;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2025),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light().copyWith(
              primary: Colors.yellow, // Cambiar el color de fondo a amarillo
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor:
                    Colors.black, // Cambiar el color de texto a negro
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      if (isDisposed) return;
      setState(() {
        isLoading = true;
        selectedDate = picked;
      });
      await _nombreusu(context);
      await _getventa();

      setState(() {
        isLoading = false; // Ocultar el CircularProgressIndicator
      });
    }
  }

  Future<void> _getventa() async {
    for (Lista element in usuarioname) {
      int num = 0;
      String apiUrl =
          'http://fopa-culiacan01.homeip.net:8088/SeguimientoEnLinea_Publicacion/SeguimientoEnLinea.svc/ConsultarClientesVisitados/';
      String codempleado = element.numero;
      String sucursal = widget.userdata.iniciarSessionAppV2Result.sucursal;
      String fecha = DateFormat('dd_MM_yyyy').format(selectedDate);
      String urlCompleta = "$apiUrl$sucursal/$codempleado/$fecha";

      final response = await http.get(Uri.parse(urlCompleta));

      if (response.statusCode == 200) {
        final clientesVisitados =
            ClientesVisitados.fromJson(jsonDecode(response.body));

        if (clientesVisitados.consultarClientesVisitadosResult.exito == "1") {
          element.totalVenta = clientesVisitados
              .consultarClientesVisitadosResult.lista
              .where((element) => element.getVenta > 0)
              .length;
        } else {}
        totalVentas += element.totalVenta!;
      }
    }
  }

  Future<void> _nombreusu(BuildContext context) async {
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Error de conexión'),
            content: const Text('No hay conexión a Internet.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Aceptar'),
              ),
            ],
          );
        },
      );
      return;
    }
    String apiUrl =
        'http://fopa-culiacan01.homeip.net:8088/SeguimientoEnLinea_Publicacion/SeguimientoEnLinea.svc/VendedoresDelSupervisor/';
    String usuario = widget.username;
    String sucursal = widget.userdata.iniciarSessionAppV2Result.sucursal;
    String urlCompleta = "$apiUrl$sucursal/$usuario";

    final response = await http.get(Uri.parse(urlCompleta));
    if (response.statusCode == 200) {
      usuarios = VendedoresSupervisor.fromJson(jsonDecode(response.body));

      setState(() {
        usuarioname = usuarios.vendedoresDelSupervisorResult.lista;
      });
    }
  }

  Future<TablaUsuarios> _numapeomanual(
      VendedoresSupervisor codemplado, int index) async {
    int i = 0;
    int u = 0;
    String apiUrl =
        'http://fopa-culiacan01.homeip.net:8088//SeguimientoEnLinea_Publicacion/SeguimientoEnLinea.svc/ConsultarGeoManualPorVendedorYCliente/';
    String codempleado =
        codemplado.vendedoresDelSupervisorResult.lista[index].numero;
    String sucursal = widget.userdata.iniciarSessionAppV2Result.sucursal;
    String fecha = DateFormat('dd_MM_yyyy').format(selectedDate);
    String urlCompleta = "$apiUrl$sucursal/$codempleado/$fecha";

    final response = await http.get(Uri.parse(urlCompleta));

    if (response.statusCode == 200) {
      final mapeomanual = Mapeomanual.fromJson(jsonDecode(response.body));

      if (mapeomanual.consultarGeoManualPorVendedorYClienteResult.exito ==
          "1") {
        for (var element
            in mapeomanual.consultarGeoManualPorVendedorYClienteResult.lista) {
          if (!element.isManual) {
            i++;
          } else {
            u++;
          }
        }
      }
    }

    return TablaUsuarios(manual: u, automatico: i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.yellow,
        title: Text(
          'Fecha seleccionada: ${DateFormat('dd/MM/yyyy').format(selectedDate)}',
          style: const TextStyle(
            fontSize: 18, // Tamaño de fuente deseado
            fontWeight: FontWeight.bold, // Negrita
            color: Color(0xFF146937),
          ),
        ),
        actions: [
          IconButton(
            color: const Color(0xFF146937),
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          HorizontalDataTable(
            leftHandSideColumnWidth: 100,
            rightHandSideColumnWidth: 600,
            isFixedHeader: true,
            headerWidgets: _getTitleWidget(),
            isFixedFooter: true,
            footerWidgets: _getTitleWidget(),
            leftSideItemBuilder: _generateFirstColumnRow,
            rightSideItemBuilder: _generateRightHandSideColumnRow,
            itemCount: usuarioname.length,
            rowSeparatorWidget: const Divider(
              color: Colors.black38,
              height: 3.0,
              thickness: 0.0,
            ),
            leftHandSideColBackgroundColor:
                const Color.fromARGB(255, 98, 170, 99),
            rightHandSideColBackgroundColor: const Color(0xFFD3EED4),
            itemExtent: 55,
          ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  List<Widget> _getTitleWidget() {
    return [
      _getTitleItemWidget('Nombre', 180),
      _getTitleItemWidget('Visitas Automaticas', 100),
      _getTitleItemWidget('Visitas Manuales', 200),
      _getTitleItemWidget('Totales Visitados', 200),
      _getTitleItemWidget('Totales Ventas', 200),
      _getTitleItemWidget('Porcentaje  Ventas/Visitas', 200),
    ];
  }

  Widget _getTitleItemWidget(String label, double width) {
    return Container(
      width: 90,
      height: 56,
      padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
      alignment: Alignment.centerLeft,
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget _generateFirstColumnRow(BuildContext context, int index) {
    return Container(
      width: 100,
      height: 52,
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      alignment: Alignment.centerLeft,
      child: Text(usuarioname[index].nombre),
    );
  }

  Widget _generateRightHandSideColumnRow(BuildContext context, int index) {
    double calcularPorcentajeVentas(int totalVentas, int totalVisitas) {
      if (totalVisitas == 0) {
        return 0.0;
      } else {
        return (totalVentas / totalVisitas) * 100;
      }
    }

    // _getventa(index);
    return FutureBuilder(
      future: _numapeomanual(usuarios, index),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Container();
        int? totalVentas = usuarioname[index].totalVenta;
        int totalVisitas = snapshot.data!.total;
        double porcentajeVentas =
            calcularPorcentajeVentas(totalVentas!, totalVisitas);

        return Row(
          children: <Widget>[
            Container(
                width: 100,
                height: 52,
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 15),
                alignment: Alignment.centerLeft,
                child: Text(snapshot.data!.automatico.toString())),
            Container(
              width: 100,
              height: 52,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 15),
              alignment: Alignment.centerLeft,
              child: Text(snapshot.data!.manual.toString()),
            ),
            Container(
              width: 100,
              height: 52,
              padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
              alignment: Alignment.centerLeft,
              child: Text(snapshot.data!.total.toString()),
            ),
            Container(
              width: 100,
              height: 52,
              padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
              alignment: Alignment.centerLeft,
              child: Text(usuarioname[index].totalVenta.toString()),
            ),
            Container(
              width: 100,
              height: 52,
              padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
              alignment: Alignment.centerLeft,
              child: Text('${porcentajeVentas.toStringAsFixed(2)}%'),
            ),
            Container(
              width: 100,
              height: 52,
              padding: const EdgeInsets.fromLTRB(5, 0, 0, 0),
              alignment: Alignment.centerLeft,
              child: Text(totalVentas.toString()),
            ),
          ],
        );
      },
    );
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Home(),
    title: "Lista de Afazeres",
    color: Color.fromARGB(255, 121, 0, 234),
  ));
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];
  
  final TextEditingController _toDoController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        if (data != null) {
          _toDoList = json.decode(data);
        }
      });
    });
  }

  void _addToDo() {
    setState(() {
      if (_toDoController.text.isNotEmpty) {
        Map<String, dynamic> newToDo = Map();
        newToDo["title"] = _toDoController.text;
        _toDoController.clear();
        newToDo["ok"] = false;
        _toDoList.add(newToDo);
        _saveData();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Lista de Afazeres"),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 121, 0, 234),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _toDoController,
                    cursorColor: const Color.fromARGB(255, 121, 0, 234),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Color.fromARGB(255, 121, 0, 234),
                              width: 2)),
                      labelText: "Nova Tarefa",
                      labelStyle: TextStyle(
                          color: Color.fromARGB(255, 121, 0, 234),
                          fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                ElevatedButton(
                  onPressed: _addToDo,
                  style: const ButtonStyle(
                      backgroundColor: MaterialStatePropertyAll(
                          Color.fromARGB(255, 121, 0, 234))),
                  child: const Text("+"),
                ),
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
            color: const Color.fromARGB(255, 121, 0, 234),
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 10),
              itemCount: _toDoList.length,
              itemBuilder: taskBuilder,
            ),
          ))
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _toDoList.sort((a, b) {
        if (a["ok"] && !b["ok"]) {
          return 1;
        } else if (!a["ok"] && b["ok"]) {
          return -1;
        } else {
          return 0;
        }
      });

      _saveData();
    });
  }

  Widget taskBuilder(context, index) {
    return Dismissible(
        onDismissed: (direction) {
          setState(() {
            Map<String, dynamic> lastRemoved = Map.from(_toDoList[index]);
            int lastremovedPosition = index;
            _toDoList.removeAt(index);
            _saveData();

            final snack = SnackBar(
              content: Text("Tarefa \"${lastRemoved["title"]}\" removida!"),
              action: SnackBarAction(
                label: "Desfazer",
                textColor: Colors.white,
                onPressed: () {
                  setState(() {
                    _toDoList.insert(lastremovedPosition, lastRemoved);
                    _saveData();
                  });
                },
              ),
              duration: const Duration(seconds: 3),
              backgroundColor: const Color.fromARGB(255, 121, 0, 234),
            );

            ScaffoldMessenger.of(context).removeCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(snack);
          });
        },
        background: Container(
          color: Colors.redAccent.shade400,
          child: const Align(
            alignment: Alignment(-0.9, 0.0),
            child: Icon(Icons.delete, color: Colors.white),
          ),
        ),
        direction: DismissDirection.startToEnd,
        key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
        child: CheckboxListTile(
          activeColor: const Color.fromARGB(255, 121, 0, 234),
          title: Text(_toDoList[index]["title"]),
          value: _toDoList[index]["ok"],
          onChanged: (check) {
            setState(() {
              _toDoList[index]["ok"] = check;
              _saveData();
            });
          },
          secondary: CircleAvatar(
            backgroundColor: const Color.fromARGB(255, 121, 0, 234),
            child: Icon(
                _toDoList[index]["ok"] ? Icons.check : Icons.error_outline,
                color: Colors.white),
          ),
        ));
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String?> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsStringSync();
    } catch (e) {
      return null;
    }
  }
}

import 'package:flutter/material.dart';
import 'package:to_do_list/screens/new_task.dart';

class TasksList extends StatefulWidget {
  const new({super.key});

  @override
  State<TasksList> createState() => _TasksListState();
}

class _TasksListState extends State<TasksList> {
  final List<bool> checked = List<bool>.filled(15, false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor:  Color(0xff0066cc),elevation: 13,
      actions: <Widget>[
        IconButton(
          icon: Icon(
            Icons.add,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context)=> NewTask()));
          },
        ),
                IconButton(
          icon: Icon(
            Icons.settings,
            color: Colors.white,
          ),
          onPressed: () {
            
          },
        ) 
      ],
      title: Text("Tasks", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),)),
      body: SafeArea(child: ListView.builder(
        itemCount: 15,
        itemBuilder:(BuildContext context, int index) {
          return Padding(
            padding: const EdgeInsets.all(10.0),
            child: Card(
              elevation: 20,
            color: Color(0xff66B2FF),
              child: ListTile(
                shape:RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12))
               , leading: Icon(Icons.list, color: Colors.white,), 
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
              Checkbox(
              activeColor: Color.fromRGBO(255, 255, 255, 1),
              checkColor:Color.fromRGBO(33, 150, 243, 0.7) ,
                value: checked[index],
                onChanged: (value) {
                  setState(() {
                    checked[index] = value ?? false;
                  });
                },
              ),
                    
                    SizedBox(width: 20),
                    Icon(Icons.delete, color: const Color.fromARGB(255, 159, 18, 18), )
                  ],
                ),
                title: Text("Task ${index+1}" ,style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25)), 
                subtitle: Text("subtitle ${index+1}"),
              ),
            ),
          );
        },)
      ),
    );
  }
}
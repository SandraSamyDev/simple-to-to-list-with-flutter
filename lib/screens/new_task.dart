import 'package:flutter/material.dart';

class NewTask extends StatefulWidget {
  const new({super.key});

  @override
  State<NewTask> createState() => _NewTaskState();
}

class _NewTaskState extends State<NewTask> {
  @override
  Widget build(BuildContext context) {
   return Scaffold(
    appBar: AppBar(backgroundColor:  Color(0xff0066cc),elevation: 13, title:Text("New Task", style: TextStyle(color: Colors.white),),leading: Builder(
      builder: (context) {
        return IconButton(icon: Icon(Icons.arrow_back_rounded), color: Colors.white, onPressed:(){ Navigator.pop(context);});
      }
    ) , ),
    body: SafeArea(child: SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("Title"),
            SizedBox(height: 5,),


            TextFormField(

              decoration: InputDecoration(
                border: OutlineInputBorder()
              ),
            ),
            SizedBox(height: 30,),

            Text("Description"),
            SizedBox(height: 5,),

            TextFormField(
                minLines: 5,
  maxLines: null,
                decoration: InputDecoration(
                border: OutlineInputBorder(),
                
              )
            ),
            SizedBox(height: 30,),


            ElevatedButton(onPressed: (){},
            style: ElevatedButton.styleFrom(
              backgroundColor: Color.fromRGBO(33, 150, 243, 1),
               shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12))
            )
             ,child: Text("Create", style: TextStyle(color: Colors.white),))
        
          ],
        ),
      ),
    ))
   );
  }
}
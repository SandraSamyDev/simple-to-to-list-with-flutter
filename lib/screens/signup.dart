import 'package:flutter/material.dart';
import 'package:to_do_list/screens/login.dart';
import 'package:to_do_list/screens/tasks_list.dart';
import 'package:to_do_list/widgets/app_logo.dart';

class Signup extends StatefulWidget {
  const new({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(30),
          child :Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 120),
              AppLogo(),
          SizedBox(height: 20,),
          Text("Sign up to make a To-Do list", style: TextStyle(fontSize: 30, fontFamily:"Roboto", fontWeight: FontWeight.bold),textAlign: TextAlign.center,),
          SizedBox(height: 20,),

          TextFormField(
            keyboardType: TextInputType.name,
            decoration:InputDecoration(
              icon: Icon(Icons.person),
              border: OutlineInputBorder(),
              label: Text("Name"),
            ),
                  
          ),
          
          SizedBox(height: 20,),
          TextFormField(
            keyboardType: TextInputType.emailAddress,

              decoration:InputDecoration(
              icon: Icon(Icons.email),
              border: OutlineInputBorder(),
              label: Text("Email"),
            ),
               
                  
          ),
          SizedBox(height: 20,),
                    TextFormField(
            keyboardType: TextInputType.visiblePassword,

              decoration:InputDecoration(
              icon: Icon(Icons.password),
              border: OutlineInputBorder(),
              label: Text("Password"),
            ),
               
                  
          ),
                    SizedBox(height: 20,),
                  
          ElevatedButton(onPressed:() {
             Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>TasksList()));
          }, style: ElevatedButton.styleFrom(
            backgroundColor:  Color.fromRGBO(33, 150, 243, 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12))
          ),child: Text("Sign in", style: TextStyle(color: Colors.white))),
          SizedBox(height: 20,),
          Text("Don't have an account?"),
          SizedBox(height: 5,),

                  
          InkWell(onTap: () {
            Navigator.pop(context);
            
          },child: Text("Log in",style: TextStyle(color: Color.fromRGBO(33, 150, 243, 1)),),)
                      ],)
        ),
      )
    );
  }
}
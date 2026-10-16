import 'package:flutter/material.dart';
import 'package:to_do_list/screens/signup.dart';
import 'package:to_do_list/screens/tasks_list.dart';
import 'package:to_do_list/widgets/app_logo.dart';

class Login extends StatefulWidget {
  const new({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
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
          Text("Login into your account", style: TextStyle(fontSize: 30, fontFamily:"Roboto", fontWeight: FontWeight.bold),textAlign: TextAlign.center,),
          SizedBox(height: 20,),

          TextFormField(
            keyboardType: TextInputType.emailAddress,
            decoration:InputDecoration(
              label: Text("Email"),
              icon: Icon(Icons.email),
              border: OutlineInputBorder()
            ),
                  
          ),
          SizedBox(height: 20,),
          SizedBox(height: 20,),

          TextFormField(
            keyboardType: TextInputType.visiblePassword,
              decoration:InputDecoration(
              label: Text("Password"),
              icon: Icon(Icons.password),
              border: OutlineInputBorder()
            ),
               
                  
          ),
          SizedBox(height: 20,),
                  
          ElevatedButton(onPressed:() {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>TasksList()));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Color.fromRGBO(33, 150, 243, 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12))), child: Text("log in", style: TextStyle(color: Colors.white) )
          )
          ,SizedBox(height: 20,),
          Text("Don't have an account?"),
          SizedBox(height: 5,),

                  
          InkWell(onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context)=>Signup()));
            
          },child: Text("Sign up", style: TextStyle(color:Color.fromRGBO(33, 150, 243, 1)),),)
                      ],)
        ),
      )
    );
  }
}
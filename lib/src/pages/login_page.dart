import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_signin_button/button_list.dart';
import 'package:flutter_signin_button/button_view.dart';
import 'package:smr/src/theme/theme.dart' as tema;
import 'package:smr/src/widgets/background.dart'; 


class LoginPage extends StatelessWidget {

 

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Stack(
             children: [
                 tema.gradientBackGround,
                 _loginCard(context),
             ],
        ),
      ),
    );
  }

  

  Widget _loginCard(BuildContext context){ 

    final size = MediaQuery.of(context).size;

      return SingleChildScrollView(
          child: Column(
              children: [
                  SafeArea(
                        child: Container(
                          height: 80.0,
                        ),
                  ),
                 Container(
                      width: size.width * 0.85,
                      margin: EdgeInsets.symmetric(vertical: 30.0),
                      padding: EdgeInsets.symmetric(vertical: 50.0),
                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.8),
                                        borderRadius: BorderRadius.circular(5.0),
                                        boxShadow: <BoxShadow>[
                                          BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 3.0,
                                              offset: Offset(0.0, 5.0),
                                              spreadRadius: 3.0
                                          )
                                        ]
                   ),
                   child: Column(
                         children: [
                             Text("Sign In", style: tema.styleText_1,),
                             _textMail(context),
                             SizedBox(height: 20.0,),
                             _textPassword(context),
                              SizedBox(height: 10.0,),
                            _loginButton(context),
                            SizedBox(height: 30.0,),
                            _newUser(),
                            SizedBox(height: 10.0,),
                            _googleLoginButton(),
                             
                         ],        
                   ),
                 ),
              ],
          ),
      );
  }

  RichText _newUser() {
    return RichText(
             text: TextSpan(
                 text: "New user?    ",
                 style: tema.styleText_2,
                 children: [
                     TextSpan(
                         text: "Sign Up",
                         style: TextStyle(
                              color: Colors.blue
                         ),
                     ),
                 ]
             ),
          );
  } 

  Widget _textMail(BuildContext context) {

      return Container(
        width: MediaQuery.of(context).size.width*0.6,
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30.0),
            border: Border.symmetric(vertical: BorderSide.none)
        ),
        child: TextField(
                   decoration: InputDecoration(
                          icon: Icon(Icons.alternate_email, color: Colors.black),
                          labelText: 'E - Mail',               
        )
       ),
     );

  } 

  Widget _textPassword(BuildContext context) {

      return Container(
        width: MediaQuery.of(context).size.width*0.6,
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30.0),
            border: Border.symmetric(vertical: BorderSide.none)
        ),
        child: TextField(
                   decoration: InputDecoration(
                          icon: Icon(Icons.lock, color: Colors.black),
                          labelText: 'Password',               
        )
       ),
     );

  } 

  Widget _loginButton( BuildContext context ) {
        return TextButton(
              
              onPressed: (){},
              child: Text("Login")
      );
  } 

  Widget _googleLoginButton() {
        return Container(
          child: SignInButton(
              Buttons.Google, 
              onPressed: () async {
              
              },
          ),
        );
  }
}
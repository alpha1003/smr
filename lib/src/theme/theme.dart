import 'package:flutter/material.dart'; 


final theme = ThemeData(
          colorScheme: ColorScheme.light().copyWith(primary:  Colors.green[200],),
          textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                           
                           primary: Colors.white,
                           backgroundColor: Colors.black,
                  ),
          ),
); 

final styleText_1 = TextStyle(
      color: Colors.black,
      fontSize: 35.0,
      fontFamily: "StyleScript"
); 

final styleText_2 = TextStyle(
      color: Colors.black,
      fontSize: 20.0,
      fontFamily: "OpenSans"
);  

final gradientBackGround = Container(
         decoration: BoxDecoration(
             gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                 colors: [
                      Color.fromRGBO(28, 146, 210, 82),
                      Color.fromRGBO(255, 247, 217, 100)
                 ],
             ),
         ),
      );
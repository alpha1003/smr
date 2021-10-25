import 'package:flutter/material.dart'; 

class Background extends StatelessWidget {
  

  @override
  Widget build(BuildContext context) {  
      return Container(
          width: MediaQuery.of(context).size.width,
          height: double.infinity,
          child: Image(image: AssetImage("images/fondo.jpg"),fit: BoxFit.cover,)
      ); 
  }
}
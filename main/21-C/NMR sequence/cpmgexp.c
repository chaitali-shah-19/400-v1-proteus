#ifndef LINT
static char SCCSid[] = "@(#)d2pul.c 21.1 03/21/08 Copyright (c) 1991-1996 Varian Assoc.,Inc. All Rights Reserved";
#endif

/* TEST-  SEQUENCIA TEST */
 

#include <standard.h>

static int phs1[4] = {1,1,1,1},
           phs3[4] = {1,1,2,2};

pulsesequence()
{     

//==================================================================
     int nexp, neco, nc;

     double ddrtc, duty, at, rof1, rof2, rof3, pw, d1, tau, tacq, dtacq,pw2;
//==================================================================

     rof1 = getval("rof1");   
     
     rof2 = getval("rof2");  

     rof3 = getval("rof3");    
     
     pw = getval("pw"); 

     pw2 = getval("pw2");    
     
     d1  = getval("d1");

     nc = getval("nc");

     sw = getval("sw");
 
     at = getval("at");

     neco = getval("neco");

     ddrtc = getval("ddrtc");

     dtacq = 1/sw;
 
     tacq = dtacq*neco;

    // rof3 = 2e-6;
//==================================================================     
     obspower(tpwr); 
     obsoffset(tof); 
     decpower(dpwr); 
     decoffset(dof); 
     
     settable(t1,4,phs1);
     settable(t3,4,phs3);

     setreceiver(t1); 

     initval(nc,v1);
      
     obsstepsize(0.25);

     initval(0,v3);

//================================================================== 
double events = 1.0;
delay(d1);
xgate(events);


//-------------------  Pulso para refrencia e calibracao (Acq normal) ------------------
  //xmtrphase(v3);
//  rgpulse(pw2,zero,0.0,0.0); 
//xmtrphase(zero);

    shapedpulse("BB90",pw2,zero,0.0,0.0); 
	delay(rof3);

   obsblank();

   startacq(alfa);

   loop(v1,v2);
         
     rcvroff();
     
     delay(rof2);
     
     rgpulse(pw,one,0.0,0.0);
  
     delay(rof1); 

     obsblank();

     rcvron();

     delay(0.000004);

     acquire(2.0*neco,dtacq);

//--------------------------
     rcvroff();
     
     delay(rof2);
     
     rgpulse(pw,one,0.0,0.0);
  
      delay(rof1); 

     obsblank();

     rcvron();

     delay(0.000004);

     acquire(2.0*neco,dtacq);

     //--------------------------
     rcvroff();
     
     delay(rof2);
     
     rgpulse(pw,one,0.0,0.0);
  
      delay(rof1); 

     obsblank();

     rcvron();

     delay(0.000004);

     acquire(2.0*neco,dtacq);

     //--------------------------
     rcvroff();
     
     delay(rof2);
     
     rgpulse(pw,one,0.0,0.0);
  
      delay(rof1); 

     obsblank();

     rcvron();

     delay(0.000004);

     acquire(2.0*neco,dtacq);
     //--------------------------
     rcvroff();
     
     delay(rof2);
     
     rgpulse(pw,one,0.0,0.0);
  
      delay(rof1); 

     obsblank();

     rcvron();

     delay(0.000004);

     acquire(2.0*neco,dtacq);
     //--------------------------
     rcvroff();
     
     delay(rof2);
     
     rgpulse(pw,one,0.0,0.0);
  
      delay(rof1); 

     obsblank();

     rcvron();

     delay(0.000004);

     acquire(2.0*neco,dtacq);
          //--------------------------
     rcvroff();
     
     delay(rof2);
     
     rgpulse(pw,one,0.0,0.0);
  
      delay(rof1); 

     obsblank();

     rcvron();

     delay(0.000004);

     acquire(2.0*neco,dtacq);
          //--------------------------
     rcvroff();
     
     delay(rof2);
     
     rgpulse(pw,one,0.0,0.0);
  
      delay(rof1); 

     obsblank();

     rcvron();

     delay(0.000004);

     acquire(2.0*neco,dtacq);
          //--------------------------
     rcvroff();
     
     delay(rof2);
     
     rgpulse(pw,one,0.0,0.0);
  
      delay(rof1); 

     obsblank();

     rcvron();

     delay(0.000004);

     acquire(2.0*neco,dtacq);
     //--------------------------
     rcvroff();
     
     delay(rof2);
     
     rgpulse(pw,one,0.0,0.0);
  
      delay(rof1); 

     obsblank();

     rcvron();

     delay(0.000004);

     acquire(2.0*neco,dtacq);

     //--------------------------
     rcvroff();
     
     delay(rof2);
     
     rgpulse(pw,one,0.0,0.0);
  
      delay(rof1); 

     obsblank();

     rcvron();

     delay(0.000004);

     acquire(2.0*neco,dtacq);

     //--------------------------
     rcvroff();
     
     delay(rof2);
     
     rgpulse(pw,one,0.0,0.0);
  
      delay(rof1); 

     obsblank();

     rcvron();

     delay(0.000004);

     acquire(2.0*neco,dtacq);

  endloop(v2);

  rcvroff();

}

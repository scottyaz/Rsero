data {
    int <lower=0> A; //the number of age classes
  
    int <lower=0> NGroups; //the number of foi groups
      
    int <lower=0> N; //the number of individuals
  
    int <lower=0> age[N]; // Age 
  
    int <lower=0, upper=1> Y[N]; // Outcome

    int<lower = 0, upper=1> seroreversion; 

    int<lower = 0, upper=1> background; 

    int <lower=1> categoryindex[N]; // 14/08

    int<lower= 1> Ncategoryclass; // 14/08

 //   int <lower=1> Ncategory[Ncategoryclass];  // 14/08
    int <lower=1> Ncategory;  // 14/08

    int<lower=1> maxNcategory; // 14/08

    int<lower=1> MatrixCategory[Ncategory,Ncategoryclass];

//    int<lower=1> index1dimension[N] ; // 14/08

  //  int <lower=1, upper=NGroups> ind_by_age[A]; // 
    
    int <lower=0> age_at_sampling[N]; 

    int <lower=0> sampling_year[N];  

    int <lower=1> NAgeGroups ; 

    int <lower=1> age_group[N] ; 
  
    int <lower=1> age_at_init[NAgeGroups]; 

    int <lower=1> K; // the number of peaks of epidemics

    real <lower = 0> prioralpha1;

    real <lower = 0> prioralpha2;

    real <lower = 0> priorbeta1;

    real <lower = 0> priorbeta2;

    real priorT1;

    real <lower = 0> priorT2;

    real <lower = 0> priorbg1;

    real <lower = 0> priorbg2;

    real <lower = 0> priorRho1;

    real <lower = 0> priorRho2;

    int <lower = 0> cat_bg;  // 1 or 0: characterizes whether we distinguish categories by different bg 

    int <lower = 0> cat_lambda; // 1 or 0: characterizes whether we distinguish categories by different FOI
}



parameters {
    real  T[K];
    real<lower=0> alpha[K];
    real<lower=0> beta[K];
    real<lower = 0, upper = 1> rho;    
    real<lower = 0, upper=1> bg2[Ncategory];
    real  Flambda2[maxNcategory,Ncategoryclass]; //14 08
}

transformed parameters {

    real x[A]; 
    real L;
    real lambda[A];
    real S[K]; // Normalization constant
    real<lower =0, upper=1> P[A,NAgeGroups,Ncategory]; //14 08 
    real<lower =0> bg[Ncategory];
    real<lower =0> Flambda[Ncategory]; //14 08
    real<lower = 0, upper=1> Like[N];  
    real c; // 14/08

     
    if(!cat_bg){
        for(i in 1:Ncategory){
            bg[i] = bg2[1];
        }
    }else{
        for(i in 1:Ncategory){
            bg[i] = bg2[i];
        }
    }
    if(background==0){
        for(i in 1:Ncategory){
            bg[i] = 0;
        }
    }
    

    for(i in 1:K){
        S[i] =0;
        for(j in 1:A){
           S[i]  =  S[i]  + exp(-((j-T[i])^2)/(beta[i])^2);
        }
    }


    for(j in 1:A){
        lambda[j] =0;
        for(i in 1:K){
            lambda[j]  =  lambda[j]  + alpha[i]/S[i]*exp(-((j-T[i])^2)/(beta[i])^2);
        }
    }
/*
     if(!cat_lambda){
        for(i in 1:Ncategory){
            Flambda[i] = 1;
        }
    }else{
        for(i in 1:Ncategory){
            Flambda[i] =exp(Flambda2[i]);
        }   
        Flambda[1] = 1;
    }
  */
   


// 14 08 
/*
    for(I in 1:Ncategoryclass){
        for(i in 1:maxNcategory){
            Flambda[I,i] =exp(Flambda2[I,i]);
        }   
        Flambda[I,1] = 1;
    }
     

     // avec index1dimensionAll : exp(sum(Flambda2))
    for(i in 1:Ncategory){
            Flambda[i] =   exp(Flambda2[I,i]);
        }   
        Flambda[1] = 1;
    }
     */
// 14 08 

    for(i in 1:Ncategory){
        c = 0;
        for(I in 1:Ncategoryclass)
            if(MatrixCategory[i,I]>1){ // if ==1, no change in the FOI
                c = c+ Flambda2[MatrixCategory[i,I], I]; // NON c'est un entier
            }
        }   
        Flambda[i] =  exp(c);// exp(Flambda2[I,i]);
       // Flambda[1] = 1;
    }


    L=1;
    if(seroreversion==0){
        for(J in 1:NAgeGroups){
            for(i in 1:Ncategory){      // Ici Ncategory est un entier et pas un tableau
                P[1,J,i ] = exp(-Flambda[i]*lambda[1]) ;
                for(j in 1:A-1){
                    x[j]=1;         
                    if(j<age_at_init[J]){
                        P[j+1,J,i] = exp(- Flambda[i]*lambda[j]) ;    
                    }else{
                        P[j+1,J,i] = P[j,J,i]*exp(- Flambda[i]*lambda[j+1]);                 
                    } 
                }
                x[A]=1;
            }
        }
    }

    if(seroreversion==1){
        for(J in 1:NAgeGroups){
            for(i in 1:Ncategory){        
                for(j in 1:A){
                    x[j] = 1; 
                    for(k in 2:j){
                        L=Flambda[i]*lambda[j-k+2];
                        x[j-k+2-1] = x[j-k+2]*exp(-(rho+L)) +rho/(L+rho)*(1- exp(-(rho+L)));
                    }
                    P[j,J,i]  = x[age_at_init[J]];
                }
            }
        }
    }






/* 14 08 


    if(seroreversion==0){
        for(J in 1:NAgeGroups){
            for(i in 1:Ncategory){      
                P[1,J,i] = exp(-Flambda[i]*lambda[1]) ;
                for(j in 1:A-1){
                    x[j]=1;         
                    if(j<age_at_init[J]){
                        P[j+1,J,i] = exp(-Flambda[i]*lambda[j]) ;    
                    }else{
                        P[j+1,J,i] = P[j,J,i]*exp(-Flambda[i]*lambda[j+1]);                 
                    } 
                }
                x[A]=1;
            }
        } 
    }

    if(seroreversion==1){
        for(J in 1:NAgeGroups){
            for(i in 1:Ncategory){        
                for(j in 1:A){
                    x[j] = 1; 
                    for(k in 2:j){
                        L=Flambda[i]*lambda[j-k+2];
                        x[j-k+2-1] = x[j-k+2]*exp(-(rho+L)) +rho/(L+rho)*(1- exp(-(rho+L)));
                    }
                    P[j,J,i]  = x[age_at_init[J]];
                }
            }
        }
    }


*/
   for(j in 1:N){
        Like[j] =1-(1-bg[categoryindex[j]])*P[age[j],age_group[j],categoryindex[j], categoryindex[j]];///q[age_group[j],categoryindex[j]] ;
    }
/*   for(j in 1:N){
        Like[j] =1-(1-bg[categoryindex[j]])*P[age[j],age_group[j],categoryindex[j]];///q[age_group[j],categoryindex[j]] ;
    }
*/

}

model {

  //FOI by group
    for (i in 1:K){
        T[i] ~ uniform(priorT1, priorT2);
        alpha[i] ~ uniform(prioralpha1, prioralpha2);
        beta[i] ~ uniform(priorbeta1, priorbeta2) ; 
    }
    rho  ~ uniform(priorRho1, priorRho2);


    for(i in 1:Ncategory){
        bg2[i] ~ uniform(priorbg1, priorbg2);   // category background infection. Size = Ncategory 
    }

   for(I in 1:Ncategoryclass){
        for(i in 1:maxNcategory){      
            Flambda2[i,I] ~ normal(0,1.73) ;
        }
    }

    for (j in 1:N) {  
        target += bernoulli_lpmf( Y[j] | Like[j]);

    }
}
 

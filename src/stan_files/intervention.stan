data {
    int <lower=0> A; //the number of age classes
  
    int <lower=0> NGroups; //the number of foi groups
      
    int <lower=0> N; //the number of individuals
  
    int <lower=0> age[N]; 
  
    int <lower=0, upper=1> Y[N]; // Outcome

    int<lower = 0, upper=1> seroreversion; 

    int<lower = 0, upper=1> background; 

    int <lower=1> categoryindex[N];

    int <lower=1> Ncategory; 

    int <lower=0> age_at_sampling[N];  

    int <lower=0> sampling_year[N]; 

    int <lower=1> NAgeGroups ;  

    int <lower=1> age_group[N] ;  
  
    int <lower=1> age_at_init[NAgeGroups];  
  
    int <lower=1> K; // the number of peaks of epidemics
 
    real <lower = 0> priorT1;

    real <lower = 0> priorT2;

    real <lower = 0> priorbg1;

    real <lower = 0> priorbg2;

    real <lower = 0> priorC1;

    real <lower = 0> priorC2;

    real <lower = 0> priorRho1;

    real <lower = 0> priorRho2;

    int <lower = 0> cat_bg;  // 1 or 0: characterizes whether we distinguish categories by different bg 

    int <lower = 0> cat_lambda; // 1 or 0: characterizes whether we distinguish categories by different FOI
}

 
parameters {
    real  T[K];
    real<lower = 0.00001>  foi[K]; 
    real<lower = 0, upper = 1> rho;    
    real<lower = 0, upper=1> bg2[Ncategory];
    real Flambda2[Ncategory];

 
}

transformed parameters {

    real x[A]; 
    real <lower=0>  L;
    real<lower = 0.00001> lambda[A];
    real Time[K];
    real<lower =0, upper=1> P[A,NAgeGroups,Ncategory];
    real<lower =0, upper = 1> bg[Ncategory];
    real<lower =0> Flambda[Ncategory];
    real<lower = 0, upper=1> Like[N];   

    Time[1] = 1;

    if(K==1){
    	for(j in 1:A){
            lambda[j] = foi[K];
		}
    } else{ 
        for(i in 2:K){
        	Time[i] = Time[i-1]+T[i];
        }
        for(j in 1:A){
            for(i in 1:K-1){
                if (j>= Time[i] && j<Time[i+1] ){
                   lambda[j] = foi[i];
                }
                if(j>=Time[K]){
                    lambda[j] = foi[K];
                }
            }
        }
    } 

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
  

	L=1;


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

   for(j in 1:N){
        Like[j] =1-(1-bg[categoryindex[j]])*P[age[j],age_group[j],categoryindex[j]];///q[age_group[j],category[j]] ;
    }

}

model {

  //FOI by group

    for (i in 1:K){
        T[i] ~ uniform(priorT1, priorT2);
        foi[i] ~ uniform(priorC1, priorC2);
    }

    for(i in 1:Ncategory){
        bg2[i] ~uniform(priorbg1, priorbg2);   // category bg . Size = Ncategory 
    }

    for(i in 1:Ncategory){
        Flambda2[i] ~ normal(0,1.73) ;
    }

    
    rho  ~ uniform(priorRho1, priorRho2);

    for(j in 1:N){
        target += bernoulli_lpmf( Y[j] | Like[j]);
   }

}
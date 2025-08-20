


double mean(Double1D v){
    double tmp=0.0;
    for(Double1D::iterator it=v.begin(); it!=v.end(); it++) tmp+=(*it);
    return tmp/double(v.size());
}

template <typename T>
T min(vector<T> v) {
    T res=v[0];
    for(auto it : v){
        if(it<res) res=it;
    }
	return res;
}

template <typename T>
T max(vector<T> v) {
    T res=v[0];
    for(auto it : v){
        if(it>res) res=it;
    }
	return res;
}



void simulated_annealing(Double1D x_ini, Double1D &x_best, double &best_f_val,  F funk, Double1D step_size)
{
    int dim=x_ini.size();
    Double1D temp_pt;
    double temp_f_val;

    int which_dir,sign;
    double f_val=funk(x_ini);
    //initialize first best value as starting pt
    best_f_val=f_val;
    x_best=x_ini;	//copy

    for(int run_ct=0; run_ct<runs_from_T_ini; run_ct++)
    {
        double T=T_initial;
        Double1D x_pt=x_ini;
        while(T>T_low_threshold)
        {
            int steps_to_take=iterations_per_fixed_T;
            while(steps_to_take>0)
            {
                temp_pt=x_pt;
                which_dir=int(my_ran.doub()*dim);	//random integer between 0 and dim-1
                //printf("which_dir=%d run_ct %d\n",which_dir, run_ct);
                sign=int(my_ran.doub()*2.0)*2-1;
                temp_pt[which_dir]+=sign*step_size[which_dir]*log(my_ran.doub());
                temp_f_val=funk(temp_pt);
                //disp(temp_pt);
                //printf("E_here=%f\n",temp_f_val);
                if(temp_f_val<f_val)
                {
                    x_pt=temp_pt;
                    f_val=temp_f_val;
                    steps_to_take--;
                }
                else
                {
                    if(my_ran.doub() < exp(-(temp_f_val-f_val)/T))
                    {
                        x_pt=temp_pt;
                        f_val=temp_f_val;
                        steps_to_take--;
                    }
                }
                //check if better than current best_val
                if(f_val<=best_f_val)
                {
                    best_f_val=f_val;
                    x_best=x_pt;
                }
            }
            T=T*decrease_T_factor;
            //printf("T %g\n",T);
        }
        cout<<run_ct<<endl;
    }

    return;
}

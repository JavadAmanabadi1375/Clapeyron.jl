
using Clapeyron, PyCall
using SQLite
using DataFrames
using Statistics
import PyPlot; const plt = PyPlot


const  R =8.314 #J/mole*k

Comparison_Compound=["Propane","Pentane","Heptane","Decane"]
# Comparison_Compound=["propane"]
StatePlot="SatL" #You can choose either Isobaric or Isothermal
Comparison_Property="Density_Kg_m3"

# Read data from database
db_path= raw"C:\Users\javam\OneDrive - Danmarks Tekniske Universitet\PhD\Database\PhdDb.db"
db=SQLite.DB(db_path)
global i=0
plt.clf()
fig_alph, ax_alph = plt.subplots(2, 2, figsize=[12, 9])

foreach(Comparison_Compound) do CompoundName
    global i+= 1
    # CompoundName="decane"
    CompoundNameK=uppercasefirst(CompoundName)
    # CompoundNameK="CarbonDioxide"
    model1 = SRK([CompoundName];idealmodel=JobackIdeal)
    model2 = CPA([CompoundName];idealmodel=JobackIdeal,radial_dist = :CS,cubicmodel=RK,alpha=SoaveAlpha)
    model3 = PCSAFT([CompoundName];idealmodel=JobackIdeal)
    model4 = SAFTgammaMie([CompoundName];idealmodel=JobackIdeal)
    model5 = PR([CompoundName];idealmodel=JobackIdeal)
    models = [model1,model2,model3,model4,model5];

    TableName=CompoundNameK*"_"*"SatL"
    qs_sat="SELECT * FROM $TableName"
    data_sat = SQLite.DBInterface.execute(db, qs_sat)
    df_sat = DataFrames.DataFrame(data_sat)

    qs_Mw="SELECT * FROM Com_Properties WHERE ComName== '$CompoundNameK'" 
    data_Mw = SQLite.DBInterface.execute(db, qs_Mw)
    df_Mw = DataFrames.DataFrame(data_Mw)
    Tc=df_Mw.Tc_k
    Dc=df_Mw.Dc_mol_L

    

    TT = df_sat.Temperature_k 
    RoL=df_sat.Density_Kg_m3
    Rov=df_sat.InternalEnergy_KJ_Kg
    PP=df_sat.Pressure_MPa


    # p = df1.Pressure_MPa.*1e6
    # T =  300
    Cp = []
    psat=[]
    model_lenght=length(models)
    crit = crit_pure.(models)

    # Obtaining the saturation curve
    T = []
    p = []
    v_l = []
    v_v = []


    for i ∈ 1:model_lenght

        append!(T,[range(170,crit[i][1],length=300)])
        sat = saturation_pressure.(models[i],T[i])
        append!(p,[[sat[i][1] for i ∈ 1:300]])
        append!(v_l,[[sat[i][2] for i ∈ 1:300]])
        append!(v_v,[[sat[i][3] for i ∈ 1:300]])

        # append!(Cp,[molar_density.(models[i],p,T)])
        # if i==1 || i==2 || i==3 || i==4

        #     # sat = saturation_pressure.(models[i],T)
        #     # append!(psat,[sat[i][1]])
            

        # end

        
    end


    if i==1

        ax_alph[1,i].plot(1e-3 ./v_l[1]./Dc,T[1]./Tc,label="SRK",linestyle="--",color="g",linewidth=2)
        ax_alph[1,i].plot(1e-3 ./v_v[1]./Dc,T[1]./Tc,label="",linestyle="--",color="g",linewidth=2)
        ax_alph[1,i].plot(1e-3 ./v_l[3]./Dc,T[3]./Tc,label="PCSAFT",linestyle=":",color="r",linewidth=2)
        ax_alph[1,i].plot(1e-3 ./v_v[3]./Dc,T[3]./Tc,label="",linestyle=":",color="r",linewidth=2)
        ax_alph[1,i].plot(1e-3 ./v_l[2]./Dc,T[2]./Tc,label="CPA",linestyle="-.",color="b",linewidth=2)
        ax_alph[1,i].plot(1e-3 ./v_v[2]./Dc,T[2]./Tc,label="",linestyle="-.",color="b",linewidth=2)
        ax_alph[1,i].plot(1e-3 ./v_l[4]./Dc,T[4]./Tc,label="SAFT-γ Mie",color="k",linewidth=2)
        ax_alph[1,i].plot(1e-3 ./v_v[4]./Dc,T[4]./Tc,label="",color="k",linewidth=2)
        ax_alph[1,i].plot(RoL./Dc,TT./Tc,label="NIST",marker="o", linestyle="none",fillstyle="none",color="k")
        ax_alph[1,i].plot(Rov./Dc,TT./Tc,label="",marker="o", linestyle="none",fillstyle="none",color="k")
        ax_alph[1,i][:set_ylabel]("\$T_{r}\$",fontsize=14)
        ax_alph[1,i][:set_xlabel]("\$ρ_{r}\$",fontsize=14)
        ax_alph[1,i][:set_ylim]([0.5,1.1])
        ax_alph[1,i].legend(loc="upper right",frameon=false,fontsize=10)

        # ax_alph[1,i].plot(T[1],p[1]./1e6,label="SRK",linestyle="--",color="g",linewidth=2)
        # ax_alph[1,i].plot(T[3],p[3]./1e6,label="PCSAFT",linestyle=":",color="r",linewidth=2)
        # ax_alph[1,i].plot(T[2],p[2]./1e6,label="CPA",linestyle="-.",color="b",linewidth=2)
        # ax_alph[1,i].plot(T[4],p[4]./1e6,label="SAFT-γ Mie",color="k",linewidth=2)
        # ax_alph[1,i].plot(TT,PP,label="NIST",marker="o", linestyle="none",fillstyle="none",color="k")
        # ax_alph[1,i][:set_ylabel]("Pressure / MPa",fontsize=14)
        # ax_alph[1,i][:set_xlabel]("Temperature / K",fontsize=14)
        # # ax_alph[1,i][:set_ylim]([170,400])
        # ax_alph[1,i][:set_xlim]([170,400])
        # ax_alph[1,i].legend(loc="upper left",frameon=false,fontsize=10)



    elseif i==2
        ax_alph[1,i].plot(1e-3 ./v_l[1]./Dc,T[1]./Tc,label="SRK",linestyle="--",color="g",linewidth=2)
        ax_alph[1,i].plot(1e-3 ./v_v[1]./Dc,T[1]./Tc,label="",linestyle="--",color="g",linewidth=2)
        ax_alph[1,i].plot(1e-3 ./v_l[3]./Dc,T[3]./Tc,label="PCSAFT",linestyle=":",color="r",linewidth=2)
        ax_alph[1,i].plot(1e-3 ./v_v[3]./Dc,T[3]./Tc,label="",linestyle=":",color="r",linewidth=2)
        ax_alph[1,i].plot(1e-3 ./v_l[2]./Dc,T[2]./Tc,label="CPA",linestyle="-.",color="b",linewidth=2)
        ax_alph[1,i].plot(1e-3 ./v_v[2]./Dc,T[2]./Tc,label="",linestyle="-.",color="b",linewidth=2)
        ax_alph[1,i].plot(1e-3 ./v_l[4]./Dc,T[4]./Tc,label="SAFT-γ Mie",color="k",linewidth=2)
        ax_alph[1,i].plot(1e-3 ./v_v[4]./Dc,T[4]./Tc,label="",color="k",linewidth=2)
        ax_alph[1,i].plot(RoL./Dc,TT./Tc,label="NIST",marker="o", linestyle="none",fillstyle="none",color="k")
        ax_alph[1,i].plot(Rov./Dc,TT./Tc,label="",marker="o", linestyle="none",fillstyle="none",color="k")
        ax_alph[1,i][:set_ylabel]("\$T_{r}\$",fontsize=14)
        ax_alph[1,i][:set_xlabel]("\$ρ_{r}\$",fontsize=14)
        ax_alph[1,i][:set_ylim]([0.4,1.1])
        ax_alph[1,i].legend(loc="upper right",frameon=false,fontsize=10)
    elseif i==3
        ax_alph[2,1].plot(1e-3 ./v_l[1]./Dc,T[1]./Tc,label="SRK",linestyle="--",color="g",linewidth=2)
        ax_alph[2,1].plot(1e-3 ./v_v[1]./Dc,T[1]./Tc,label="",linestyle="--",color="g",linewidth=2)
        ax_alph[2,1].plot(1e-3 ./v_l[3]./Dc,T[3]./Tc,label="PCSAFT",linestyle=":",color="r",linewidth=2)
        ax_alph[2,1].plot(1e-3 ./v_v[3]./Dc,T[3]./Tc,label="",linestyle=":",color="r",linewidth=2)
        ax_alph[2,1].plot(1e-3 ./v_l[2]./Dc,T[2]./Tc,label="CPA",linestyle="-.",color="b",linewidth=2)
        ax_alph[2,1].plot(1e-3 ./v_v[2]./Dc,T[2]./Tc,label="",linestyle="-.",color="b",linewidth=2)
        ax_alph[2,1].plot(1e-3 ./v_l[4]./Dc,T[4]./Tc,label="SAFT-γ Mie",color="k",linewidth=2)
        ax_alph[2,1].plot(1e-3 ./v_v[4]./Dc,T[4]./Tc,label="",color="k",linewidth=2)
        ax_alph[2,1].plot(RoL./Dc,TT./Tc,label="NIST",marker="o", linestyle="none",fillstyle="none",color="k")
        ax_alph[2,1].plot(Rov./Dc,TT./Tc,label="",marker="o", linestyle="none",fillstyle="none",color="k")
        ax_alph[2,1][:set_ylabel]("\$T_{r}\$",fontsize=14)
        ax_alph[2,1][:set_xlabel]("\$ρ_{r}\$",fontsize=14)
        ax_alph[2,1][:set_ylim]([0.5,1.1])
        ax_alph[2,1].legend(loc="upper right",frameon=false,fontsize=10)
    elseif i==4
        # ax_alph[2,2].plot(1e-3 ./v_l[1]./Dc,T[1]./Tc,label="SRK",linestyle="--",color="g",linewidth=2)
        # ax_alph[2,2].plot(1e-3 ./v_v[1]./Dc,T[1]./Tc,label="",linestyle="--",color="g",linewidth=2)
        # ax_alph[2,2].plot(1e-3 ./v_l[3]./Dc,T[3]./Tc,label="PCSAFT",linestyle=":",color="r",linewidth=2)
        # ax_alph[2,2].plot(1e-3 ./v_v[3]./Dc,T[3]./Tc,label="",linestyle=":",color="r",linewidth=2)
        # ax_alph[2,2].plot(1e-3 ./v_l[2]./Dc,T[2]./Tc,label="CPA",linestyle="-.",color="b",linewidth=2)
        # ax_alph[2,2].plot(1e-3 ./v_v[2]./Dc,T[2]./Tc,label="",linestyle="-.",color="b",linewidth=2)
        # ax_alph[2,2].plot(1e-3 ./v_l[4]./Dc,T[4]./Tc,label="SAFT-γ Mie",color="k",linewidth=2)
        # ax_alph[2,2].plot(1e-3 ./v_v[4]./Dc,T[4]./Tc,label="",color="k",linewidth=2)
        # ax_alph[2,2].plot(RoL./Dc,TT./Tc,label="NIST",marker="o", linestyle="none",fillstyle="none",color="k")
        # ax_alph[2,2].plot(Rov./Dc,TT./Tc,label="",marker="o", linestyle="none",fillstyle="none",color="k")
        # ax_alph[2,2][:set_ylabel]("\$T_{r}\$",fontsize=14)
        # ax_alph[2,2][:set_xlabel]("\$ρ_{r}\$",fontsize=14)
        # ax_alph[2,2][:set_ylim]([0.5,1.1])
        # ax_alph[2,2].legend(loc="upper right",frameon=false,fontsize=10)

        ax_alph[2,2].plot(1e-3 ./v_l[1]./Dc,p[1]./1e6,label="SRK",linestyle="--",color="g",linewidth=2)
        ax_alph[2,2].plot(1e-3 ./v_v[1]./Dc,p[1]./1e6,label="",linestyle="--",color="g",linewidth=2)
        ax_alph[2,2].plot(1e-3 ./v_l[3]./Dc,p[3]./1e6,label="PCSAFT",linestyle=":",color="r",linewidth=2)
        ax_alph[2,2].plot(1e-3 ./v_v[3]./Dc,p[3]./1e6,label="",linestyle=":",color="r",linewidth=2)
        ax_alph[2,2].plot(1e-3 ./v_l[2]./Dc,p[2]./1e6,label="CPA",linestyle="-.",color="b",linewidth=2)
        ax_alph[2,2].plot(1e-3 ./v_v[2]./Dc,p[2]./1e6,label="",linestyle="-.",color="b",linewidth=2)
        ax_alph[2,2].plot(1e-3 ./v_l[4]./Dc,p[4]./1e6,label="SAFT-γ Mie",color="k",linewidth=2)
        ax_alph[2,2].plot(1e-3 ./v_v[4]./Dc,p[4]./1e6,label="",color="k",linewidth=2)
        ax_alph[2,2].plot(RoL./Dc,PP,label="NIST",marker="o", linestyle="none",fillstyle="none",color="k")
        ax_alph[2,2].plot(Rov./Dc,PP,label="",marker="o", linestyle="none",fillstyle="none",color="k")
        ax_alph[2,2][:set_ylabel]("\$P_{r}\$",fontsize=14)
        ax_alph[2,2][:set_xlabel]("\$ρ_{r}\$",fontsize=14)
        # ax_alph[2,2][:set_xlim]([1.5,3.5])
        ax_alph[2,2].legend(loc="upper right",frameon=false,fontsize=10)
    end



    # plt.title(condition1*" "* CompoundNameK)
    # plt.xlim([0.3,9])
    # plt.ylim([-1,1])
end
display(plt.gcf())
plt.savefig("T_Density.pdf")







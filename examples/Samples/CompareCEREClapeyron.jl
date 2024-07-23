
using Clapeyron, PyCall
using SQLite
using DataFrames
using Statistics
import PyPlot; const plt = PyPlot


const  R =8.314 #J/mole*k

# Comparison_Compound=["Propane","Pentane","Heptane","Decane"]
Comparison_Compound=["Propane"]
StatePlot="Isobaric" #You can choose either Isobaric or Isothermal
Comparison_Property="Density_Kg_m3"

# Read data from database
db_path= raw"C:\Users\javam\OneDrive - Danmarks Tekniske Universitet\PhD\Database\PhDdb.db"
db=SQLite.DB(db_path)
global i=0
plt.clf()
fig_alph, ax_alph = plt.subplots(figsize=[12, 9])

foreach(Comparison_Compound) do CompoundName
    global i+= 1
    # CompoundName="decane"
    CompoundNameK=uppercasefirst(CompoundName)
    # CompoundNameK="CarbonDioxide"
        model1 = SRK([CompoundName];idealmodel=JobackIdeal)
        model2 = CPA([CompoundName];idealmodel=JobackIdeal,radial_dist = :KG,cubicmodel=RK,alpha=SoaveAlpha)
        model3 = PCSAFT([CompoundName];idealmodel=JobackIdeal)
        model4 = SAFTgammaMie([CompoundName];idealmodel=JobackIdeal)
        model5 = PR([CompoundName];idealmodel=JobackIdeal)
        models = [model1,model2,model3,model4,model5];

    TableName=CompoundNameK*"_"*StatePlot
    condition1= StatePlot=="Isothermal" ? "Temperature_k==300" : "Pressure_MPa==20"
    qs1 = "SELECT * FROM $TableName WhERE $condition1"
    # qs1 = "SELECT * FROM $TableName WhERE $condition1 AND Phase=='liquid'"
    # qs1 = "SELECT * FROM $TableName WhERE $condition1 AND Phase=='liquid' AND Pressure_MPa>7" 
    data1 = SQLite.DBInterface.execute(db, qs1)
    df1 = DataFrames.DataFrame(data1)
    x1= StatePlot=="Isobaric" ? df1.Temperature_k : df1.Pressure_MPa

    p =20*1e6
    T = df1.Temperature_k 
    # p = df1.Pressure_MPa.*1e6
    # T =  300
    Cp = []
    psat=[]
    model_lenght=length(models)
    # crit = crit_pure.(models)
    for i ∈ 1:model_lenght

        # if i==4 
        #     ∂²A∂T²_v=[]

        #     for f in T

        #         ∂p∂V,∂p∂T,∂²A∂V∂T,∂²A∂V²,∂²A∂T²,∂A∂V,∂A∂T,A= Gathering_Derivatives.(models[i],p,f)
        #         append!(∂²A∂T²_v,∂²A∂T²)
            
        #     end
        #     append!(Cp,[-T.*∂²A∂T²_v])

        # else
        #     append!(Cp,[isochoric_heat_capacity.(models[i],p,T)])
        # end

        # append!(Cp,[isobaric_heat_capacity.(models[i],p,T)])
        # if i==5

        #     append!(Cp,[isobaric_heat_capacity.(models[i],p,T)])

        # else
        #     append!(Cp,[joule_thomson_coefficient.(models[i],p,T)])

        # end

        # if i==6
        #     append!(Cp,[isochoric_heat_capacity.(models[i],p,T)])

        # elseif i==5
        #     append!(Cp,[isobaric_heat_capacity.(models[i],p,T)])

        # else

        #     append!(Cp,[speed_of_sound.(models[i],p,T)])

        # end

        append!(Cp,[molar_density.(models[i],p,T)])
        # if i==1 || i==2 || i==3 || i==4

        #     # sat = saturation_pressure.(models[i],T)
        #     # append!(psat,[sat[i][1]])
            

        # end

        
    end


    qs_Mw="SELECT * FROM Com_Properties WHERE ComName== '$CompoundNameK'" 
    data_Mw = SQLite.DBInterface.execute(db, qs_Mw)
    df_Mw = DataFrames.DataFrame(data_Mw)

    # Plot data from CERE
    qs_CERE = "SELECT * FROM CERE_EOS"
    data_CERE = SQLite.DBInterface.execute(db, qs_CERE)
    df_CERE = DataFrames.DataFrame(data_CERE)


    xAxix= StatePlot=="Isobaric" ? x1./df_Mw.Tc_k : x1./df_Mw.Pc_MPa

    if Comparison_Property=="Cp_J_gk"

        yAxis=(df1.Cp_J_gk.*df_Mw.Mw./R)
    
    elseif Comparison_Property=="Cv_J_gk"
    
        yAxis=(df1.Cv_J_gk.*df_Mw.Mw./R)
    
    elseif Comparison_Property=="Density_Kg_m3"
        
        yAxis=df1.Density_Kg_m3/(df_Mw.Mw)

    elseif Comparison_Property=="JouleThomson_K_MPa"

        yAxis=df1.JouleThomson_K_MPa

    elseif Comparison_Property=="Soundspd_m_s"

        yAxis=df1.Soundspd_m_s

    end

            ax_alph.plot(xAxix,Cp[1]*1e-3,label="SRK",linestyle="--",color="g",linewidth=2)
            ax_alph.plot(xAxix,Cp[5]*1e-3,label="PR",linestyle="-.",color="b",linewidth=2)
            ax_alph.plot(xAxix,Cp[3]*1e-3,label="PCSAFT",linestyle=":",color="r",linewidth=2)
            ax_alph.plot(xAxix,Cp[2]*1e-3,label="CPA",linestyle="-",color="k",linewidth=2)


            ax_alph.plot(xAxix,df_CERE.Ro_C3_SRK*1e-3,label="SRK_CERE",linestyle="--",color="g",linewidth=2)
            ax_alph.plot(xAxix,df_CERE.Ro_C3_PR*1e-3,label="PR_CERE",linestyle="-.",color="b",linewidth=2)
            ax_alph.plot(xAxix,df_CERE.Ro_C3_PCSAFT*1e-3,label="PCSAFT_CERE",linestyle=":",color="r",linewidth=2)
            ax_alph.plot(xAxix,df_CERE.Ro_C3_CPA*1e-3,label="CPA_CERE",linestyle="-",color="k",linewidth=2)


            # ax_alph[1,1].plot(xAxix,yAxis,label="NIST",marker="o", linestyle="none",fillstyle="none",color="k")
            xlabelName= StatePlot=="Isobaric" ? "Tr" : "Pr" 
            ax_alph[:set_xlabel](xlabelName,fontsize=14)
            ax_alph[:set_ylabel]("ρ (mol.L⁻¹)",fontsize=14)
            ax_alph.legend(loc="upper right",frameon=false,fontsize=10)


    # plt.title(condition1*" "* CompoundNameK)
    # plt.xlim([0.3,9])
    # plt.ylim([-1,1])
end
display(plt.gcf())
# plt.savefig("Compare_results.pdf")







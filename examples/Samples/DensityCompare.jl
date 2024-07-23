
using Clapeyron, PyCall
using SQLite
using DataFrames
using Statistics
import PyPlot; const plt = PyPlot


const  R =8.314 #J/mole*k

Comparison_Compound=["Propane","Pentane","Heptane","Decane"]
# Comparison_Compound=["Pentane"]
StatePlot="Isobaric" #You can choose either Isobaric or Isothermal
Comparison_Property="JouleThomson_K_MPa"

# Read data from database
db_path= raw"C:\Users\javam\OneDrive - Danmarks Tekniske Universitet\PhD\Database\PhDdb.db"
db=SQLite.DB(db_path)
global i=0
plt.clf()
fig_alph, ax_alph = plt.subplots(2, 2, figsize=[12, 9])

foreach(Comparison_Compound) do CompoundName
    global i+= 1
    # CompoundName="decane"
    CompoundNameK=uppercasefirst(CompoundName)
    # CompoundNameK="CarbonDioxide"
        model5 = JobackIdeal([CompoundName];)
        model6 = JobackIdeal([CompoundName];)
        model1 = SRK([CompoundName];idealmodel=JobackIdeal)
        model2 = CPA([CompoundName];idealmodel=JobackIdeal,radial_dist = :CS,cubicmodel=RK,alpha=SoaveAlpha)
        model3 = PCSAFT([CompoundName];idealmodel=JobackIdeal)
        model4 = SAFTgammaMie([CompoundName];idealmodel=JobackIdeal)
        models = [model1,model2,model3,model4,model5,model6];

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
        if i==5

            append!(Cp,[isobaric_heat_capacity.(models[i],p,T)])

        else
            append!(Cp,[joule_thomson_coefficient.(models[i],p,T)])

        end

        # if i==6
        #     append!(Cp,[isochoric_heat_capacity.(models[i],p,T)])

        # elseif i==5
        #     append!(Cp,[isobaric_heat_capacity.(models[i],p,T)])

        # else

        #     append!(Cp,[speed_of_sound.(models[i],p,T)])

        # end

        # append!(Cp,[molar_density.(models[i],p,T)])
        # if i==1 || i==2 || i==3 || i==4

        #     # sat = saturation_pressure.(models[i],T)
        #     # append!(psat,[sat[i][1]])
            

        # end

        
    end


    qs_Mw="SELECT * FROM Com_Properties WHERE ComName== '$CompoundNameK'" 
    data_Mw = SQLite.DBInterface.execute(db, qs_Mw)
    df_Mw = DataFrames.DataFrame(data_Mw)

    # Plot data from CERE
    qs_CERE = "SELECT * FROM CERE"
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


    if i==1
        if Comparison_Property=="Density_Kg_m3"

            ax_alph[1,i].plot(xAxix,Cp[1]*1e-3,label="SRK",linestyle="--",color="g",linewidth=2)
            ax_alph[1,i].plot(xAxix,df_CERE.Ro_mol_m3_C3*1e-3,label="CPA",linestyle="-.",color="b",linewidth=2)
            # plt.plot(xAxix,Cp[2],label="CPA",linestyle="-.",color="k")
            ax_alph[1,i].plot(xAxix,Cp[3]*1e-3,label="PCSAFT",linestyle=":",color="r",linewidth=2)
            ax_alph[1,i].plot(xAxix,Cp[4]*1e-3,label="SAFT-γ Mie",color="k",linewidth=2)
            ax_alph[1,i].plot(xAxix,yAxis,label="NIST",marker="o", linestyle="none",fillstyle="none",color="k")
            xlabelName= StatePlot=="Isobaric" ? "Tr" : "Pr" 
            ax_alph[1,i][:set_xlabel](xlabelName,fontsize=14)
            ax_alph[1,i][:set_ylabel]("ρ (mol.L⁻¹)",fontsize=14)
            ax_alph[1,i].legend(loc="upper right",frameon=false,fontsize=10)

        elseif Comparison_Property=="Cp_J_gk" || Comparison_Property=="Cv_J_gk"

            #Cp, Cv
            ax_alph[1,i].plot(xAxix,Cp[1]./R,label="SRK",linestyle="--",color="g",linewidth=2)
            ax_alph[1,i].plot(xAxix,df_CERE.CVR_C3+Cp[5]/R,label="CPA",linestyle="-.",color="b",linewidth=2)
            ax_alph[1,i].plot(xAxix,Cp[3]./R,label="PCSAFT",linestyle=":",color="r",linewidth=2)
            ax_alph[1,i].plot(xAxix,Cp[4]./R,label="SAFT-γ Mie",color="k",linewidth=2)
            ax_alph[1,i].plot(xAxix,yAxis,label="NIST",marker="o", linestyle="none",fillstyle="none",color="k")
            xlabelName= StatePlot=="Isobaric" ? "Tr" : "Pr" 
            ax_alph[1,i][:set_xlabel](xlabelName,fontsize=14)
            ax_alph[1,i][:set_ylabel]("Cv/R",fontsize=14)
            ax_alph[1,i].legend(loc="lower right",frameon=false,fontsize=10)


        elseif Comparison_Property=="JouleThomson_K_MPa"

            #Joule-Thomson Coefficient
            ax_alph[1,i].plot(xAxix,Cp[1]*1e6,label="SRK",linestyle="--",color="g",linewidth=2)
            ax_alph[1,i].plot(xAxix,(-df_CERE.JT_K_MPa_C3./((df_CERE.CPR_C3*R).+Cp[5]))*1e6,label="CPA",linestyle="-.",color="b",linewidth=2)
            ax_alph[1,i].plot(xAxix,Cp[3]*1e6,label="PCSAFT",linestyle=":",color="r",linewidth=2)
            ax_alph[1,i].plot(xAxix,Cp[4]*1e6,label="SAFT-γ Mie",color="k",linewidth=2)
            ax_alph[1,i].plot(xAxix,yAxis,label="NIST",marker="o", linestyle="none",fillstyle="none",color="k")
            xlabelName= StatePlot=="Isobaric" ? "Tr" : "Pr" 
            ax_alph[1,i][:set_xlabel](xlabelName,fontsize=14)
            ax_alph[1,i][:set_ylabel]("\$μ_{JT}\\:(K\\:\\cdot MPa^{-1})\$",fontsize=14)
            ax_alph[1,i].legend(loc="upper left",frameon=false,fontsize=10) 


        elseif  Comparison_Property=="Soundspd_m_s"

            #Speed of sound
            ax_alph[1,i].plot(xAxix,Cp[1],label="SRK",linestyle="--",color="g",linewidth=2)
            ax_alph[1,i].plot(xAxix,df_CERE.u_m_s_C3.*((df_CERE.CPR_C3.+Cp[5]/R)./(df_CERE.CVR_C3.+Cp[6]/R)).^(0.5),label="CPA",linestyle="-.",color="b",linewidth=2)
            ax_alph[1,i].plot(xAxix,Cp[3],label="PCSAFT",linestyle=":",color="r",linewidth=2)
            ax_alph[1,i].plot(xAxix,Cp[4],label="SAFT-γ Mie",color="k",linewidth=2)
            ax_alph[1,i].plot(xAxix,yAxis,label="NIST",marker="o", linestyle="none",fillstyle="none",color="k")
            xlabelName= StatePlot=="Isobaric" ? "Tr" : "Pr" 
            ax_alph[1,i][:set_xlabel](xlabelName,fontsize=14)
            ax_alph[1,i][:set_ylabel]("\$u\\:(m\\:\\cdot s^{-1})\$",fontsize=14)
            ax_alph[1,i].legend(loc="upper right",frameon=false,fontsize=10) 

        end

    elseif i==2

        if Comparison_Property=="Density_Kg_m3"

            ax_alph[1,i].plot(xAxix,Cp[1]*1e-3,label="SRK",linestyle="--",color="g",linewidth=2)
            ax_alph[1,i].plot(xAxix,df_CERE.Ro_mol_m3_C5[1:51]*1e-3,label="CPA",linestyle="-.",color="b",linewidth=2)
            # plt.plot(xAxix,Cp[2],label="CPA",linestyle="-.",color="k")
            ax_alph[1,i].plot(xAxix,Cp[3]*1e-3,label="PCSAFT",linestyle=":",color="r",linewidth=2)
            ax_alph[1,i].plot(xAxix,Cp[4]*1e-3,label="SAFT-γ Mie",color="k",linewidth=2)
            ax_alph[1,i].plot(xAxix,yAxis,label="NIST",marker="o", linestyle="none",fillstyle="none",color="k")
            xlabelName= StatePlot=="Isobaric" ? "Tr" : "Pr" 
            ax_alph[1,i][:set_xlabel](xlabelName,fontsize=14)
            ax_alph[1,i][:set_ylabel]("ρ (mol.L⁻¹)",fontsize=14)
            ax_alph[1,i].legend(loc="upper right",frameon=false,fontsize=10)

        elseif Comparison_Property=="Cp_J_gk" || Comparison_Property=="Cv_J_gk"

            #Cp, Cv
            ax_alph[1,i].plot(xAxix,Cp[1]./R,label="SRK",linestyle="--",color="g",linewidth=2)
            ax_alph[1,i].plot(xAxix,df_CERE.CVR_C5[1:51]+Cp[5]/R,label="CPA",linestyle="-.",color="b",linewidth=2)
            ax_alph[1,i].plot(xAxix,Cp[3]./R,label="PCSAFT",linestyle=":",color="r",linewidth=2)
            ax_alph[1,i].plot(xAxix,Cp[4]./R,label="SAFT-γ Mie",color="k",linewidth=2)
            ax_alph[1,i].plot(xAxix,yAxis,label="NIST",marker="o", linestyle="none",fillstyle="none",color="k")
            xlabelName= StatePlot=="Isobaric" ? "Tr" : "Pr" 
            ax_alph[1,i][:set_xlabel](xlabelName,fontsize=14)
            ax_alph[1,i][:set_ylabel]("Cv/R",fontsize=14)
            ax_alph[1,i].legend(loc="lower right",frameon=false,fontsize=10)


        elseif Comparison_Property=="JouleThomson_K_MPa"

            #Joule-Thomson Coefficient
            ax_alph[1,i].plot(xAxix,Cp[1]*1e6,label="SRK",linestyle="--",color="g",linewidth=2)
            ax_alph[1,i].plot(xAxix,(-df_CERE.JT_K_MPa_C5[1:51]./((df_CERE.CPR_C5[1:51]*R).+Cp[5]))*1e6,label="CPA",linestyle="-.",color="b",linewidth=2)
            ax_alph[1,i].plot(xAxix,Cp[3]*1e6,label="PCSAFT",linestyle=":",color="r",linewidth=2)
            ax_alph[1,i].plot(xAxix,Cp[4]*1e6,label="SAFT-γ Mie",color="k",linewidth=2)
            ax_alph[1,i].plot(xAxix,yAxis,label="NIST",marker="o", linestyle="none",fillstyle="none",color="k")
            xlabelName= StatePlot=="Isobaric" ? "Tr" : "Pr" 
            ax_alph[1,i][:set_xlabel](xlabelName,fontsize=14)
            ax_alph[1,i][:set_ylabel]("\$μ_{JT}\\:(K\\:\\cdot MPa^{-1})\$",fontsize=14)
            ax_alph[1,i].legend(loc="upper left",frameon=false,fontsize=10) 


        elseif  Comparison_Property=="Soundspd_m_s"

            #Speed of sound
            ax_alph[1,i].plot(xAxix,Cp[1],label="SRK",linestyle="--",color="g",linewidth=2)
            ax_alph[1,i].plot(xAxix,df_CERE.u_m_s_C5[1:51].*((df_CERE.CPR_C5[1:51].+Cp[5]/R)./(df_CERE.CVR_C5[1:51].+Cp[6]/R)).^(0.5),label="CPA",linestyle="-.",color="b",linewidth=2)
            ax_alph[1,i].plot(xAxix,Cp[3],label="PCSAFT",linestyle=":",color="r",linewidth=2)
            ax_alph[1,i].plot(xAxix,Cp[4],label="SAFT-γ Mie",color="k",linewidth=2)
            ax_alph[1,i].plot(xAxix,yAxis,label="NIST",marker="o", linestyle="none",fillstyle="none",color="k")
            xlabelName= StatePlot=="Isobaric" ? "Tr" : "Pr" 
            ax_alph[1,i][:set_xlabel](xlabelName,fontsize=14)
            ax_alph[1,i][:set_ylabel]("\$u\\:(m\\:\\cdot s^{-1})\$",fontsize=14)
            ax_alph[1,i].legend(loc="upper right",frameon=false,fontsize=10) 

        end

    elseif i==3

        if Comparison_Property=="Density_Kg_m3"

            ax_alph[2,1].plot(xAxix,Cp[1]*1e-3,label="SRK",linestyle="--",color="g",linewidth=2)
            ax_alph[2,1].plot(xAxix,df_CERE.Ro_mol_m3_C7[1:40]*1e-3,label="CPA",linestyle="-.",color="b",linewidth=2)
            # plt.plot(xAxix,Cp[2],label="CPA",linestyle="-.",color="k")
            ax_alph[2,1].plot(xAxix,Cp[3]*1e-3,label="PCSAFT",linestyle=":",color="r",linewidth=2)
            ax_alph[2,1].plot(xAxix,Cp[4]*1e-3,label="SAFT-γ Mie",color="k",linewidth=2)
            ax_alph[2,1].plot(xAxix,yAxis,label="NIST",marker="o", linestyle="none",fillstyle="none",color="k")
            xlabelName= StatePlot=="Isobaric" ? "Tr" : "Pr" 
            ax_alph[2,1][:set_xlabel](xlabelName,fontsize=14)
            ax_alph[2,1][:set_ylabel]("ρ (mol.L⁻¹)",fontsize=14)
            ax_alph[2,1].legend(loc="upper right",frameon=false,fontsize=10)

        elseif Comparison_Property=="Cp_J_gk" || Comparison_Property=="Cv_J_gk"

            #Cp, Cv
            ax_alph[2,1].plot(xAxix,Cp[1]./R,label="SRK",linestyle="--",color="g",linewidth=2)
            ax_alph[2,1].plot(xAxix,df_CERE.CVR_C7[1:40]+Cp[5]/R,label="CPA",linestyle="-.",color="b",linewidth=2)
            ax_alph[2,1].plot(xAxix,Cp[3]./R,label="PCSAFT",linestyle=":",color="r",linewidth=2)
            ax_alph[2,1].plot(xAxix,Cp[4]./R,label="SAFT-γ Mie",color="k",linewidth=2)
            ax_alph[2,1].plot(xAxix,yAxis,label="NIST",marker="o", linestyle="none",fillstyle="none",color="k")
            xlabelName= StatePlot=="Isobaric" ? "Tr" : "Pr" 
            ax_alph[2,1][:set_xlabel](xlabelName,fontsize=14)
            ax_alph[2,1][:set_ylabel]("Cv/R",fontsize=14)
            ax_alph[2,1].legend(loc="lower right",frameon=false,fontsize=10)

        elseif Comparison_Property=="JouleThomson_K_MPa"

            #Joule-Thomson Coefficient
            ax_alph[2,1].plot(xAxix,Cp[1]*1e6,label="SRK",linestyle="--",color="g",linewidth=2)
            ax_alph[2,1].plot(xAxix,(-df_CERE.JT_K_MPa_C7[1:40]./((df_CERE.CPR_C7[1:40]*R).+Cp[5]))*1e6,label="CPA",linestyle="-.",color="b",linewidth=2)
            ax_alph[2,1].plot(xAxix,Cp[3]*1e6,label="PCSAFT",linestyle=":",color="r",linewidth=2)
            ax_alph[2,1].plot(xAxix,Cp[4]*1e6,label="SAFT-γ Mie",color="k",linewidth=2)
            ax_alph[2,1].plot(xAxix,yAxis,label="NIST",marker="o", linestyle="none",fillstyle="none",color="k")
            xlabelName= StatePlot=="Isobaric" ? "Tr" : "Pr" 
            ax_alph[2,1][:set_xlabel](xlabelName,fontsize=14)
            ax_alph[2,1][:set_ylabel]("\$μ_{JT}\\:(K\\:\\cdot MPa^{-1})\$",fontsize=14)
            ax_alph[2,1].legend(loc="upper left",frameon=false,fontsize=10) 

        elseif  Comparison_Property=="Soundspd_m_s"

            #Speed of sound
            ax_alph[2,1].plot(xAxix,Cp[1],label="SRK",linestyle="--",color="g",linewidth=2)
            ax_alph[2,1].plot(xAxix,df_CERE.u_m_s_C7[1:40].*((df_CERE.CPR_C7[1:40].+Cp[5]/R)./(df_CERE.CVR_C7[1:40].+Cp[6]/R)).^(0.5),label="CPA",linestyle="-.",color="b",linewidth=2)
            ax_alph[2,1].plot(xAxix,Cp[3],label="PCSAFT",linestyle=":",color="r",linewidth=2)
            ax_alph[2,1].plot(xAxix,Cp[4],label="SAFT-γ Mie",color="k",linewidth=2)
            ax_alph[2,1].plot(xAxix,yAxis,label="NIST",marker="o", linestyle="none",fillstyle="none",color="k")
            xlabelName= StatePlot=="Isobaric" ? "Tr" : "Pr" 
            ax_alph[2,1][:set_xlabel](xlabelName,fontsize=14)
            ax_alph[2,1][:set_ylabel]("\$u\\:(m\\:\\cdot s^{-1})\$",fontsize=14)
            ax_alph[2,1].legend(loc="upper right",frameon=false,fontsize=10)

        end

    else

        if Comparison_Property=="Density_Kg_m3"

            ax_alph[2,2].plot(xAxix,Cp[1]*1e-3,label="SRK",linestyle="--",color="g",linewidth=2)
            ax_alph[2,2].plot(xAxix,df_CERE.Ro_mol_m3_C10[1:42]*1e-3,label="CPA",linestyle="-.",color="b",linewidth=2)
            # plt.plot(xAxix,Cp[2],label="CPA",linestyle="-.",color="k")
            ax_alph[2,2].plot(xAxix,Cp[3]*1e-3,label="PCSAFT",linestyle=":",color="r",linewidth=2)
            ax_alph[2,2].plot(xAxix,Cp[4]*1e-3,label="SAFT-γ Mie",color="k",linewidth=2)
            ax_alph[2,2].plot(xAxix,yAxis,label="NIST",marker="o", linestyle="none",fillstyle="none",color="k")
            xlabelName= StatePlot=="Isobaric" ? "Tr" : "Pr" 
            ax_alph[2,2][:set_xlabel](xlabelName,fontsize=14)
            ax_alph[2,2][:set_ylabel]("ρ (mol.L⁻¹)",fontsize=14)
            ax_alph[2,2].legend(loc="upper right",frameon=false,fontsize=10)

        elseif Comparison_Property=="Cp_J_gk" || Comparison_Property=="Cv_J_gk"

            #Cp, Cv
            ax_alph[2,2].plot(xAxix,Cp[1]./R,label="SRK",linestyle="--",color="g",linewidth=2)
            ax_alph[2,2].plot(xAxix,df_CERE.CVR_C10[1:42]+Cp[5]/R,label="CPA",linestyle="-.",color="b",linewidth=2)
            ax_alph[2,2].plot(xAxix,Cp[3]./R,label="PCSAFT",linestyle=":",color="r",linewidth=2)
            ax_alph[2,2].plot(xAxix,Cp[4]./R,label="SAFT-γ Mie",color="k",linewidth=2)
            ax_alph[2,2].plot(xAxix,yAxis,label="NIST",marker="o", linestyle="none",fillstyle="none",color="k")
            xlabelName= StatePlot=="Isobaric" ? "Tr" : "Pr" 
            ax_alph[2,2][:set_xlabel](xlabelName,fontsize=14)
            ax_alph[2,2][:set_ylabel]("Cv/R",fontsize=14)
            ax_alph[2,2].legend(loc="lower right",frameon=false,fontsize=10)

        elseif Comparison_Property=="JouleThomson_K_MPa"

            
            #Joule-Thomson Coefficient
            ax_alph[2,2].plot(xAxix,Cp[1]*1e6,label="SRK",linestyle="--",color="g",linewidth=2)
            ax_alph[2,2].plot(xAxix,(-df_CERE.JT_K_MPa_C10[1:42]./((df_CERE.CPR_C10[1:42]*R).+Cp[5]))*1e6,label="CPA",linestyle="-.",color="b",linewidth=2)
            ax_alph[2,2].plot(xAxix,Cp[3]*1e6,label="PCSAFT",linestyle=":",color="r",linewidth=2)
            ax_alph[2,2].plot(xAxix,Cp[4]*1e6,label="SAFT-γ Mie",color="k",linewidth=2)
            ax_alph[2,2].plot(xAxix,yAxis,label="NIST",marker="o", linestyle="none",fillstyle="none",color="k")
            xlabelName= StatePlot=="Isobaric" ? "Tr" : "Pr" 
            ax_alph[2,2][:set_xlabel](xlabelName,fontsize=14)
            ax_alph[2,2][:set_ylabel]("\$μ_{JT}\\:(K\\:\\cdot MPa^{-1})\$",fontsize=14)
            ax_alph[2,2].legend(loc="upper left",frameon=false,fontsize=10) 

        elseif  Comparison_Property=="Soundspd_m_s"

            #Speed of sound
            ax_alph[2,2].plot(xAxix,Cp[1],label="SRK",linestyle="--",color="g",linewidth=2)
            ax_alph[2,2].plot(xAxix,df_CERE.u_m_s_C10[1:42].*((df_CERE.CPR_C10[1:42].+Cp[5]/R)./(df_CERE.CVR_C10[1:42].+Cp[6]/R)).^(0.5),label="CPA",linestyle="-.",color="b",linewidth=2)
            ax_alph[2,2].plot(xAxix,Cp[3],label="PCSAFT",linestyle=":",color="r",linewidth=2)
            ax_alph[2,2].plot(xAxix,Cp[4],label="SAFT-γ Mie",color="k",linewidth=2)
            ax_alph[2,2].plot(xAxix,yAxis,label="NIST",marker="o", linestyle="none",fillstyle="none",color="k")
            xlabelName= StatePlot=="Isobaric" ? "Tr" : "Pr" 
            ax_alph[2,2][:set_xlabel](xlabelName,fontsize=14)
            ax_alph[2,2][:set_ylabel]("\$u\\:(m\\:\\cdot s^{-1})\$",fontsize=14)
            ax_alph[2,2].legend(loc="upper right",frameon=false,fontsize=10) 

        end

    end

    # plt.title(condition1*" "* CompoundNameK)
    # plt.xlim([0.3,9])
    # plt.ylim([-1,1])
end
display(plt.gcf())
plt.savefig("Joule_Thomson.pdf")







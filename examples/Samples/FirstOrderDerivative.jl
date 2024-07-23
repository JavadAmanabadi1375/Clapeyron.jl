
using Clapeyron, PyCall
using SQLite
using DataFrames
using Statistics
using ExcelFiles
using XLSX
import PyPlot; const plt = PyPlot
using Plots


#Database path
db_path= raw"C:\Users\javam\Desktop\Study Plan\Db\AlkanesSR.db"
db=SQLite.DB(db_path)

#Initial Condition of Datagathering
Comparison_Compound=["propane"]
StatePlot="Isothermal" #You can choose either Isobaric or Isothermal
Comparison_Property="Cv_J_gk"

const  R =8.314 #J/mole*k


plt.clf()
foreach(Comparison_Compound) do CompoundName
    CompoundNameK=uppercasefirst(CompoundName)
    # CompoundNameK="CarbonDioxide"

    # model5 = JobackIdeal([CompoundName];)
    # model6 = JobackIdeal([CompoundName];)
    model1 = SRK([CompoundName];idealmodel=JobackIdeal)
    model2 = CPA([CompoundName];idealmodel=JobackIdeal,radial_dist = :CS,cubicmodel=RK,alpha=SoaveAlpha)
    model3 = PCSAFT([CompoundName];idealmodel=JobackIdeal)
    model4 = SAFTgammaMie([CompoundName];idealmodel=JobackIdeal)
    # models = [model4];
    models = [model1,model2,model3,model4];
    model_lenght=length(models)

    TableName=CompoundNameK*"_"*StatePlot
    condition1= StatePlot=="Isothermal" ? "Temperature_k==300" : "Pressure_MPa==5"
    # qs1 = "SELECT * FROM $TableName WhERE $condition1"
    # qs1 = "SELECT * FROM $TableName WhERE $condition1 AND Phase=='liquid'"
    qs1 = "SELECT * FROM $TableName WhERE $condition1 AND Phase=='liquid' AND Pressure_MPa>7" 
    data1 = SQLite.DBInterface.execute(db, qs1)
    df1 = DataFrames.DataFrame(data1)
    x1= StatePlot=="Isobaric" ? df1.Temperature_k : df1.Pressure_MPa

    qs_Mw="SELECT * FROM Com_Properties WHERE ComName== '$CompoundNameK'" 
    data_Mw = SQLite.DBInterface.execute(db, qs_Mw)
    df_Mw = DataFrames.DataFrame(data_Mw)

    # p =5*1e6
    # T = df1.Temperature_k 
    p = df1.Pressure_MPa.*1e6
    T =  300

    xAxix= StatePlot=="Isobaric" ? x1./df_Mw.Tc_k : x1./df_Mw.Pc_MPa
    # xAxix=df1.Pressure_MPa


    dPdV=((df1.Soundspd_m_s.*df1.Soundspd_m_s).*(df_Mw.Mw./1000).*(df1.Cv_J_gk.*df_Mw.Mw))./
    ((df1.Cp_J_gk.*df_Mw.Mw).*(-df1.Volume_m3_Kg.*df1.Volume_m3_Kg).*1e-6)
    dPdT=(-((((df1.Cp_J_gk.-df1.Cv_J_gk).*df_Mw.Mw.+R).*(dPdV))./(T))).^0.5
    # Plot data from CERE
    qs_CERE = "SELECT * FROM CERE"
    data_CERE = SQLite.DBInterface.execute(db, qs_CERE)
    df_CERE = DataFrames.DataFrame(data_CERE)
   
    global  cellNo=8
    for i ∈ 1:model_lenght

        ∂²A∂V∂T_v=[]
        ∂²A∂V²_v=[]
        ∂²A∂T²_v=[]
        ∂A∂V_v=[]
        ∂A∂T_v=[]
        ∂p∂V_v=[]
        ∂p∂T_v=[]
        A_v=[]
        A_vres=[]
        ∂A∂V_vres=[]
        ∂A∂T_vres=[]
        ahs_V=[]
        adisp_V=[]
        achain_V=[]
        aassociation_V=[]
        AresT=[]

        for f in p

            ∂p∂V,∂p∂T,∂²A∂V∂T,∂²A∂V²,∂²A∂T²,∂A∂V,∂A∂T,A,A_res,∂A∂T_res,∂A∂V_res= Gathering_Derivatives.(models[i],f,T)
            # ahs,adisp,achain,aassociation=a_res_gathering.(models[i],f,T)
            append!(∂p∂V_v,∂p∂V)
            append!(∂p∂T_v,∂p∂T)
            append!(∂²A∂V∂T_v,∂²A∂V∂T)
            append!(∂²A∂V²_v,∂²A∂V²)
            append!(∂A∂V_v,∂A∂V)
            append!(∂A∂T_v,∂A∂T)
            append!(∂²A∂T²_v,∂²A∂T²)
            append!(A_v,A)
            append!(A_vres,A_res)
            append!(∂A∂V_vres,∂A∂V_res)
            append!(∂A∂T_vres,∂A∂T_res)

            # append!(ahs_V,ahs)
            # append!(adisp_V,adisp)
            # append!(achain_V,achain)
            # append!(aassociation_V,aassociation)
            # append!(AresT,aassociation+achain+ahs+adisp)

            global  cellNo += 1
        end
        
        if i==1
            # plt.plot(xAxix,∂p∂T_v*1e-5,label="SRK",linestyle="--",color="k")
            # plt.plot(xAxix,∂p∂V_v*1e-12,label="SRK",linestyle="--",color="k")
            plt.plot(xAxix,∂²A∂V∂T_v,label="SRK",linestyle="--",color="k")

        elseif i==2
            # plt.plot(xAxix,∂p∂T_v*1e-5,label="CPA",linestyle="-.",color="k")
            # plt.plot(xAxix,∂A∂T_v,label="CPA",linestyle="-.",color="k")
            # plt.plot(xAxix,∂p∂V_v*1e-12,label="CPA",linestyle="-.",color="k")
            # plt.plot(xAxix,df_CERE.dPdT_C10*1e-5,label="CPA",linestyle="-.",color="k")

        elseif i==3
            # plt.plot(xAxix,∂p∂T_v*1e-5,label="PCSAFT",linestyle=":",color="k")
            plt.plot(xAxix,∂²A∂V∂T_v,label="PCSAFT",linestyle=":",color="k")
            # plt.plot(xAxix,∂p∂V_v*1e-12,label="PCSAFT",linestyle=":",color="k")

        elseif i==4
            # plt.plot(xAxix,∂p∂T_v*1e-5,label="SAFT-γ Mie",color="k")
            plt.plot(xAxix,∂²A∂V∂T_v,label="SAFT-γ Mie",color="k")
            # plt.plot(xAxix,∂p∂V_v*1e-12,label="SAFT-γ Mie",color="k")
            # plt.plot(xAxix,dPdT*1e-5,label="NIST",marker="o", linestyle="none",fillstyle="none",color="k")

        end


        xlabelName= StatePlot=="Isobaric" ? "Tr" : "Pr" 
        plt.xlabel(xlabelName,fontsize=16)
        # plt.ylabel("∂P/∂V",fontsize=16)
        # plt.ylabel("dP/dT [bar/K]",fontsize=16)
        # plt.ylabel("∂²A∂V² [J/(mol·K·m³)] *1e13",fontsize=16)
        plt.ylabel("∂²A∂V∂T [J/(mol·K2·m³)] *1e13",fontsize=16)
        # plt.ylabel("∂²A∂T² [ J/(mol·K²)]",fontsize=16)
        # plt.ylabel("dP/dV [GPa/Liter]",fontsize=16)
        plt.legend(loc="upper right",frameon=false,fontsize=8)
        # plt.title(condition1*" "*"$CompoundNameK")
        display(plt.gcf())
    end



end
    







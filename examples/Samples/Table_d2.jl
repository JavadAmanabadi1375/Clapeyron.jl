
using Clapeyron, PyCall
using SQLite
using DataFrames
using Statistics
using ExcelFiles
using XLSX
import PyPlot; const plt = PyPlot


const  R =8.314 #J/mole*k

StatePlot="Isothermal" #You can choose either Isobaric or Isothermal
Comparison_Property=["Cp_J_gk","Cv_J_gk","JouleThomson_K_MPa","Soundspd_m_s"]
# Comparison_Property=["Soundspd_m_s"]

# Comparison_Compound=["ethane","propane","butane","pentane","hexane","heptane","octane","nonane","decane"]
# Comparison_Compound=["ethane","propane"]
Comparison_Compound=["hexane"]
ModelNames=["SRK","PR","CPA","CK-SAFT","PC-SAFT",
            "SAFT-VR Mie (2013)","SAFT-γ-Mie","GERG (2008)"]


# Read data from database
db_path= raw"C:\Users\javam\Desktop\Study Plan\Db\AlkanesSR.db"
db=SQLite.DB(db_path)


# Open the Excel file
file_path="C:\\Users\\javam\\ClapeyronNew\\Clapeyron.jl\\examples\\Samples\\AARDN.xlsx"

global  cellNo=10

foreach(Comparison_Compound) do CompoundName
    CompoundNameK=uppercasefirst(CompoundName)
    # CompoundNameK="CarbonDioxide"

    foreach(Comparison_Property) do property


        model1 = SRK([CompoundName];idealmodel=WalkerIdeal)
        model2 = PR([CompoundName];idealmodel=WalkerIdeal)
        model3 = CPA([CompoundName];idealmodel=WalkerIdeal,radial_dist = :CS,cubicmodel=RK,alpha=SoaveAlpha)
        model4 = CKSAFT([CompoundName];idealmodel=WalkerIdeal)
        model5 = PCSAFT([CompoundName];idealmodel=WalkerIdeal)
        model6 = SAFTVRMie([CompoundName];idealmodel=WalkerIdeal)
        model7 = SAFTgammaMie([CompoundName];idealmodel=WalkerIdeal)
        model8 = GERG2008([CompoundName])

        models = [model1,model2,model3,model4,model5,model6,model7,model8];
        model_lenght=length(models)

        TableName=CompoundNameK*"_"*StatePlot
        condition1= StatePlot=="Isothermal" ? "Temperature_k==300" : "Pressure_MPa==3"
        # qs1 = "SELECT * FROM $TableName WhERE $condition1"
        qs1 = "SELECT * FROM $TableName WhERE $condition1 AND Phase=='liquid' AND Pressure_MPa>7" 
        data1 = SQLite.DBInterface.execute(db, qs1)
        df1 = DataFrames.DataFrame(data1)
        x1= StatePlot=="Isobaric" ? df1.Temperature_k : df1.Pressure_MPa

        qs_Mw="SELECT * FROM Com_Properties WHERE ComName== '$CompoundNameK'" 
        data_Mw = SQLite.DBInterface.execute(db, qs_Mw)
        df_Mw = DataFrames.DataFrame(data_Mw)


        # p =3*1e6
        # T = df1.Temperature_k 
        p = df1.Pressure_MPa.*1e6
        T=300
        
        for i ∈ 8:8
            
            ∂²A∂T²_v=[]
            Cp = []
            Cpid=[]
            Cvid=[]
            if property=="Cp_J_gk"

    
                # append!(Cp,[isobaric_heat_capacity.(models[i],p,T)])
                Cp=isobaric_heat_capacity.(models[i],p,T)
                exp_values=(df1.Cp_J_gk.*df_Mw.Mw)

                # # CPA Model results ------------------------------------
                # IdeaModel = JobackIdeal([CompoundName];)
                # append!(Cpid,[isobaric_heat_capacity.(IdeaModel,p,T)])
                # qs_CERE = "SELECT * FROM CERE"
                # data_CERE = SQLite.DBInterface.execute(db, qs_CERE)
                # df_CERE = DataFrames.DataFrame(data_CERE)
                # Cp=df_CERE.dPdT_C7.*R+Cpid[1]
                # #-------------------CPA Model results---------------------

                if i==1
                    sheetname="J"
 
                elseif i==2 
                    sheetname="N"

                elseif i==3
                    sheetname="R"

                elseif i==4
                    sheetname="V"

                elseif i==5
                    sheetname="Z"

                elseif i==6
                    sheetname="AH"

                elseif i==7
                    sheetname="AL"

                elseif i==8
                    sheetname="AP"

                end
    
            elseif property=="Cv_J_gk"

                if i==6 || i==7

                    for f in p

                        ∂p∂V,∂p∂T,∂²A∂V∂T,∂²A∂V²,∂²A∂T²,∂A∂V,∂A∂T,A= Gathering_Derivatives.(models[i],f,T)
                        append!(∂²A∂T²_v,∂²A∂T²)
                    
                    end
                    # append!(Cp,[-T.*∂²A∂T²_v])
                    Cp=-T.*∂²A∂T²_v

                else

                    # append!(Cp,[isochoric_heat_capacity.(models[i],p,T)])
                    Cp=isochoric_heat_capacity.(models[i],p,T)

                    # # CPA Model results ------------------------------------
                    # IdeaModel = JobackIdeal([CompoundName];)
                    # append!(Cvid,[isochoric_heat_capacity.(IdeaModel,p,T)])
                    # qs_CERE = "SELECT * FROM CERE"
                    # data_CERE = SQLite.DBInterface.execute(db, qs_CERE)
                    # df_CERE = DataFrames.DataFrame(data_CERE)
                    # Cp=df_CERE.dPdT_C10.*R+Cvid[1]
                    # #-------------------CPA Model results---------------------

                end
    
                exp_values=(df1.Cv_J_gk.*df_Mw.Mw)

                # # CPA Model results ------------------------------------
                # qs_CERE = "SELECT * FROM CERE"
                # data_CERE = SQLite.DBInterface.execute(db, qs_CERE)
                # df_CERE = DataFrames.DataFrame(data_CERE)
                # # Cp=df_CERE.dPdT_C7
                # #-------------------CPA Model results---------------------

                if i==1
                    sheetname="I"
 
                elseif i==2 
                    sheetname="M"

                elseif i==3
                    sheetname="Q"

                elseif i==4
                    sheetname="U"

                elseif i==5
                    sheetname="Y"

                elseif i==6
                    sheetname="AG"

                elseif i==7
                    sheetname="AK"

                elseif i==8
                    sheetname="AO"

                end
    
            elseif property=="JouleThomson_K_MPa"
    
    
                # append!(Cp,[joule_thomson_coefficient.(models[i],p,T)])
                Cp=joule_thomson_coefficient.(models[i],p,T)
                exp_values=(df1.JouleThomson_K_MPa*1e-6)
                # println(exp_values.-Cp)

                    # # CPA Model results ------------------------------------
                    # qs_CERE = "SELECT * FROM CERE"
                    # data_CERE = SQLite.DBInterface.execute(db, qs_CERE)
                    # df_CERE = DataFrames.DataFrame(data_CERE)
                    # # Cp=df_CERE.dPdT_C7
                    # #-------------------CPA Model results---------------------

                # # CPA Model results ------------------------------------
                # IdeaModel = JobackIdeal([CompoundName];)
                # append!(Cpid,[isobaric_heat_capacity.(IdeaModel,p,T)])
                # qs_CERE = "SELECT * FROM CERE"
                # data_CERE = SQLite.DBInterface.execute(db, qs_CERE)
                # df_CERE = DataFrames.DataFrame(data_CERE)
                # Cp=-df_CERE.dPdV_C7./((df_CERE.dPdT_C7*R).+Cpid[1])
                # #-------------------CPA Model results---------------------
        

                if i==1
                    sheetname="H"
 
                elseif i==2 
                    sheetname="L"

                elseif i==3
                    sheetname="P"

                elseif i==4
                    sheetname="T"

                elseif i==5
                    sheetname="X"

                elseif i==6
                    sheetname="AF"

                elseif i==7
                    sheetname="AJ"

                elseif i==8
                    sheetname="AN"

                end
    
            elseif property=="Soundspd_m_s"
    
                # append!(Cp,[speed_of_sound.(models[i],p,T)])
                Cp=speed_of_sound.(models[i],p,T)
                exp_values=(df1.Soundspd_m_s)

                    # # CPA Model results ------------------------------------
                    # qs_CERE = "SELECT * FROM CERE"
                    # data_CERE = SQLite.DBInterface.execute(db, qs_CERE)
                    # df_CERE = DataFrames.DataFrame(data_CERE)
                    # # Cp=df_CERE.dPdT_C7
                    # #-------------------CPA Model results---------------------
                
                # CPA Model results ------------------------------------
                # IdeaModel = JobackIdeal([CompoundName];)
                # IdeaModel2 = JobackIdeal([CompoundName];)
                # append!(Cpid,[isobaric_heat_capacity.(IdeaModel,p,T)])
                # append!(Cvid,[isochoric_heat_capacity.(IdeaModel2,p,T)])
                # qs_CERE = "SELECT * FROM CERE"
                # data_CERE = SQLite.DBInterface.execute(db, qs_CERE)
                # df_CERE = DataFrames.DataFrame(data_CERE)
                # Cp=df_CERE.dPdV_C10.*((df_CERE.dPdT_C7.+Cpid[1]/R)./(df_CERE.dPdT_C10.+Cvid[1]/R)).^(0.5)
                # #-------------------CPA Model results---------------------

                if i==1
                    sheetname="K"
 
                elseif i==2 
                    sheetname="O"

                elseif i==3
                    sheetname="S"

                elseif i==4
                    sheetname="W"

                elseif i==5
                    sheetname="AA"

                elseif i==6
                    sheetname="AI"

                elseif i==7
                    sheetname="AM"

                elseif i==8
                    sheetname="AQ"

                end

            end

                # # Find the index of NaN value
                non_nan_indices = [j for (j, x) in enumerate(Cp) if (isnan(x) || isinf(x))]
                foreach(reverse(non_nan_indices)) do y
                    deleteat!(Cp, y)
                    deleteat!(exp_values, y)
    
                end
                
                # ABSOLUTE RELATIVE DEVIATION       
                ARD = abs.((Cp) - (exp_values))
                # println(ARD)
                # AVERAGE ABSOLUTE RELATIVE DEVIATION
                AARD = 100 * abs.(mean((ARD ./ abs.(exp_values))))
    
                    XLSX.openxlsx(file_path, mode="rw") do xf
    
                        sheet=xf[1]
    
                        sheet[sheetname*"$cellNo"]=AARD
                    
                    end


            
        end

    end
    
   global  cellNo += 1
end



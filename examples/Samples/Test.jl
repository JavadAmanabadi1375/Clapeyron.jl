# # Example vector with NaN value
# Cp=[]
# # append!(Cp,[1.54585,2,3,4.585858,5,NaN, NaN,NaN,Inf,Inf])
# Cp=[1.54585,2,3,4.585858,5,NaN, NaN,NaN,Inf,Inf]
# exp_values=[1,2,3,4,5,6,7,8,9.8585,10]

#         # Find the index of NaN value
#         non_nan_indices = [j for (j, x) in enumerate(Cp) if (isnan(x) || isinf(x))]
#         foreach(reverse(non_nan_indices)) do y
#             deleteat!(Cp, y)
#             deleteat!(exp_values, y)

#         end

# aa=[(1,2,3),(4,5,6),(7,8,9)]
# first_elements = [x[1] for x in aa]
# println(first_elements)
# a=3
# using Plots
import PyPlot; const plt = PyPlot


categories = ["Ans", "Achain", "Aes"]
data = [
    [0.2, 0.3, 0.5],  # Data for Adiso
    [0.4, 0.4, 0.2],  # Data for Aes
    [0.3, 0.2, 0.5],  # Data for Ans
    [0.5, 0.3, 0.2]   # Data for Achain
]

plot_titles = ["Adiso", "Aes", "Ans", "Achain"]
colors = [:blue, :orange, :gray]

fig, axs = plt.subplots(2, 2, figsize=(10, 8))

for i in 1:4
    axs[i].bar(categories, data[i], color=colors)
    axs[i].set_title(plot_titles[i])
    axs[i].set_ylabel("Relative Frequency of Occurrence")
end

# plt.tight_layout()
display(plt.gcf())


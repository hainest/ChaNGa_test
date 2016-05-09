import numpy as np
import matplotlib.pyplot as plt
import csv
import plotting

theta = [0.1, 0.2, 0.3, 0.4, 0.5, 0.7, 0.9]
types = []
with open('timings.csv', 'r') as file:
    reader = csv.reader(file)
    next(reader, None)  # skip header
    for row in reader:
        types.append(row[0])

timings = np.genfromtxt('timings.csv', delimiter=',', usecols=(1, 2, 3, 4, 5, 6, 7))
timings_gravity = np.genfromtxt('timings_gravity.csv', delimiter=',', usecols=(1, 2, 3, 4, 5, 6, 7))

# Remove CPU timings
timings = np.delete(timings, [types.index('CPU'), types.index('CPU-SMP')], 0)
timings_gravity = np.delete(timings_gravity, [types.index('CPU'), types.index('CPU-SMP')], 0)
types.remove('CPU')
types.remove('CPU-SMP')
gpu_index = types.index('GPU-SMP')

fig, ax = plotting.make_fig(size=(5, 3.8))

bar_width = 0.70 / len(types)
spacer = 0.1 * bar_width
alpha = 0.7
indices = np.arange(len(theta))
offsets = np.arange(len(types)) * bar_width + spacer
colors = ('orange', 'darkviolet', 'green', 'coral')

gpu_time = timings[gpu_index, :]
scaled_timings = timings / gpu_time
scaled_timings_gravity = timings_gravity / gpu_time
non_gravity_timings = scaled_timings - scaled_timings_gravity
grav_frac = timings_gravity / timings

for i in indices:
    plt.bar(i + offsets, non_gravity_timings[:, i], width=bar_width, alpha=alpha, color=colors)
    plt.bar(i + offsets, scaled_timings_gravity[:, i], width=bar_width, alpha=alpha, color='white', edgecolor=colors, bottom=non_gravity_timings[:, i], hatch='//')
    plt.text(i, 1.02 * scaled_timings[gpu_index, i], '{0:.2f}'.format(timings[gpu_index, i]), fontsize=8)
    
    for j in range(len(types)):
        y = non_gravity_timings[j, i] + 0.5 * scaled_timings_gravity[j, i]
        plt.text(i + j * 1.15 * bar_width, y, '{0:d}%'.format(int(100.0 * grav_frac[j, i])), fontsize=6, rotation=90.0)

plt.legend(types, loc='upper center', ncol=3, fancybox=True, shadow=True, fontsize=8)
l = ax.get_legend()
for i in range(len(types)):
    l.legendHandles[i].set_color(colors[i])

# These muck up the legend, so leave them down here
grey = '0.4'
plt.plot((0, len(theta)), (0.95, 0.95), color=grey, linewidth=0.9, alpha=0.2)
plt.plot((0, len(theta)), (0.90, 0.90), color=grey, linewidth=0.9, alpha=0.2)
plt.plot((0, len(theta)), (0.80, 0.80), color=grey, linewidth=0.9, alpha=0.2)
plt.text(indices[-1] + 0.75, 0.65, 'Speedup', color=grey, fontsize=7, rotation=90.0)
plt.text(indices[-1] + 0.75, 0.95, '5%', color=grey, fontsize=5)
plt.text(indices[-1] + 0.75, 0.90, '10%', color=grey, fontsize=5)
plt.text(indices[-1] + 0.75, 0.80, '20%', color=grey, fontsize=5)

plt.xticks(indices, theta)
plt.yticks(())
plt.ylim((0.0, 1.3))
plt.xlabel(r'$\theta$ (opening angle)')
plt.ylabel(r'$\left\langle t_{{\rm step}}\right\rangle\,(s)$')

plotting.save_fig(fig, 'gpu-timings.png')

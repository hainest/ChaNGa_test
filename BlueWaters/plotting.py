import matplotlib.pyplot as plt
from mpl_toolkits.axes_grid1 import ImageGrid
import numpy as np

text_sizes = {'axis':4, 'label':6, 'title':10, 'annotation':8}

def make_fig(size=(6.0, 2.5)):
    fig, ax = plt.subplots(1, 1, figsize=size, dpi=400)
    fig.subplots_adjust(left=0.05, right=0.95)
    ax.tick_params(axis='x', labelsize=text_sizes['axis'])
    ax.tick_params(axis='y', labelsize=text_sizes['axis'])
    return fig, ax

def make_fig_grid(x=1, y=3, size=(6.0, 2.5), use_cbar=True):
    fig = plt.figure(figsize=size, dpi=400)
    fig.subplots_adjust(left=0.05, right=0.95)
    
    if use_cbar:
        grid = ImageGrid(fig, 111, nrows_ncols=(x, y), axes_pad=0.1,
                         cbar_mode='each', cbar_location='top',
                         cbar_size="7%", cbar_pad="2%")
    else:
        grid = ImageGrid(fig, 111, nrows_ncols=(x, y), axes_pad=0.1, aspect=True)

    for i in range(x * y):
        grid[i].tick_params(axis='x', labelsize=text_sizes['axis'])
        grid[i].tick_params(axis='y', labelsize=text_sizes['axis'])
    return fig, grid

def save_fig(fig, name):
    fig.savefig(name, dpi=400, bbox_inches='tight', pad_inches=0.02)
    plt.close()

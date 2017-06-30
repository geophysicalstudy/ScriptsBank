"""

This script runs an Magnetic Amplitude Inversion (MAI) from TMI data.
Magnetic amplitude data are weakly sensitive to the orientation of
magnetization, and can therefore better recover the location and geometry of
magnetic bodies in the presence of remanence. The algorithm is inspired from
Li & Shearer (2008), with an added iterative sensitivity weighting strategy to
counter the vertical streatchin that the old code had

This is done in three parts:

1- TMI data are inverted for an equivalent source layer.

2-The equivalent source layer is used to predict component data -> amplitude

3- Amplitude data are inverted in 3-D for an effective susceptibility model

Created on December 7th, 2016

@author: fourndo@gmail.com

"""
from SimPEG import Mesh, Directives, Maps, InvProblem, Optimization, DataMisfit, Inversion, Utils, Regularization
from SimPEG.Utils import mkvc
import SimPEG.PF as PF
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Rectangle
import os

#work_dir = "C:\\Users\\DominiqueFournier\\ownCloud\\Research\\Kevitsa\\Modeling\\MAG\\"
#work_dir = "C:\\Users\\DominiqueFournier\\ownCloud\\\Research\\Modelling\\Synthetic\\Block_Gaussian_topo\\"
#work_dir = "C:\\Users\\DominiqueFournier\\ownCloud\\Research\\Modelling\\Synthetic\\Nut_Cracker\\"
#work_dir = "C:\\Egnyte\\Private\\dominiquef\\Projects\\4559_CuMtn_ZTEM\\Modeling\\MAG\\A1_Fenton\\"
work_dir = 'C:\\Users\\DominiqueFournier\\ownCloud\\Research\\Kevitsa\\Modeling\\MAG\\Aiborne\\'
out_dir = "SimPEG_PF_Inv\\"
tile_dirl2 = 'Tiles_l2\\'
tile_dirlp = 'Tiles_lp\\'
input_file = "SimPEG_MAG.inp"

max_mcell = 2.0e+5
min_Olap = 5e+2

# %%
# Read in the input file which included all parameters at once
# (mesh, topo, model, survey, inv param, etc.)
driver = PF.MagneticsDriver.MagneticsDriver_Inv(work_dir + input_file)

os.system('if not exist ' + work_dir + out_dir + ' mkdir ' + work_dir+out_dir)

# Access the mesh and survey information
mesh = driver.mesh
survey = driver.survey
actv = driver.activeCells

# # TILE THE PROBLEM 
lx = int(np.floor(np.sqrt(max_mcell/mesh.nCz)))
##%% Create tiles
## Begin tiling

# In the x-direction
ntile = 1
Olap  = -1
dx = [mesh.hx.min(), mesh.hy.min()]
# Cell size


while Olap < min_Olap:
# for ii in range(5):

    ntile += 1

    # Set location of SW corners
    x0 = np.asarray([mesh.vectorNx[0], mesh.vectorNx[-1] - lx*dx[0]])

    dx_t = np.round( ( x0[1] - x0[0] ) / ( (ntile-1) * dx[0]) )

    if ntile>2:
        x1 = np.r_[x0[0],
                   x0[0] + np.cumsum(np.ones(ntile-2) * dx_t * dx[0]),
                   x0[1]]
    else:
        x1 = np.asarray([x0[0],x0[1]])


    x2 = x1 + lx*dx[0];

#     y1 = np.ones(x1.shape[0])*np.min(locs[:,1]);
#     y2 = np.ones(x1.shape[0])*(np.min(locs[:,1]) + nCx*dx);

    Olap = x1[0] + lx*dx[0] - x1[1];


# Save x-corner location
xtile = np.c_[x1,x2]



# In the Y-direction
ntile = 1
Olap  = -1

# Cell size

while Olap < min_Olap:
# for ii in range(5):

    ntile += 1

    # Set location of SW corners
    y0 = np.asarray([mesh.vectorNy[0],mesh.vectorNy[-1] - lx*dx[0]])

    dy_t = np.round( ( y0[1] - y0[0] ) / ( (ntile-1) * dx[0]) )

    if ntile>2:
        y1 = np.r_[y0[0],
                   y0[0] + np.cumsum(np.ones(ntile-2) * dy_t * dx[0]),
                   y0[1]]
    else:
        y1 = np.asarray([y0[0],y0[1]])


    y2 = y1 + lx*dx[0];

#     x1 = np.ones(y1.shape[0])*np.min(locs[:,0]);
#     x2 = np.ones(y1.shape[0])*(np.min(locs[:,0]) + nCx*dx);

    Olap = y1[0] + lx*dx[0] - y1[1];


# Save x-corner location
ytile = np.c_[y1,y2]


X1,Y1 = np.meshgrid(x1,y1)
X1,Y1 = mkvc(X1), mkvc(Y1)
X2,Y2 = np.meshgrid(x2,y2)
X2,Y2 = mkvc(X2), mkvc(Y2)

# Plot data and tiles
rxLoc = survey.srcField.rxList[0].locs
fig, ax1 = plt.figure(), plt.subplot()
PF.Magnetics.plot_obs_2D(rxLoc,survey.dobs, ax=ax1)
for ii in range(X1.shape[0]):
    ax1.add_patch(Rectangle((X1[ii],Y1[ii]),X2[ii]-X1[ii],Y2[ii]-Y1[ii], facecolor = 'none', edgecolor='k'))
ax1.set_aspect('equal')

# LOOP THROUGH TILES
npadxy = 8
core_x = np.ones(lx)*dx[0]
core_y = np.ones(lx)*dx[1]
expf = 1.3 

os.system('if not exist ' + work_dir + out_dir + tile_dirl2 + ' mkdir ' + work_dir+out_dir+tile_dirl2)
os.system('if not exist ' + work_dir + out_dir + tile_dirlp + ' mkdir ' + work_dir+out_dir+tile_dirlp)

for tt in range(X1.shape[0]):
    
    midX = np.mean([X1[tt], X2[tt]])
    midY = np.mean([Y1[tt], Y2[tt]])
    
    # Create new mesh
    padx = np.r_[dx[0]*expf**(np.asarray(range(npadxy))+1)]
    pady = np.r_[dx[1]*expf**(np.asarray(range(npadxy))+1)]
    
    hx = np.r_[padx[::-1], core_x, padx]
    hy = np.r_[pady[::-1], core_y, pady]
#        hz = np.r_[padb*2.,[33,26],np.ones(25)*22,[18,15,12,10,8,7,6], np.ones(18)*5,5*expf**(np.asarray(range(2*npad)))]
    hz = mesh.hz

    mesh_t = Mesh.TensorMesh([hx,hy,hz], 'CC0')

#    mtemp._x0 = [x0[ii]-np.sum(padb), y0[ii]-np.sum(padb), mesh.x0[2]]

    mesh_t._x0 = (mesh_t.x0[0] + midX, mesh_t.x0[1]+midY, mesh.x0[2])
#        meshes.append(mtemp)
    # Grab the right data
    xlim = [mesh_t.vectorCCx[npadxy], mesh_t.vectorCCx[-npadxy]]
    ylim = [mesh_t.vectorCCy[npadxy], mesh_t.vectorCCy[-npadxy]]
    
    ind_t = np.all([rxLoc[:,0] > xlim[0], rxLoc[:,0] < xlim[1],
                    rxLoc[:,1] > ylim[0], rxLoc[:,1] < ylim[1]], axis=0)
            
    
    
    rxLoc_t = PF.BaseMag.RxObs(rxLoc[ind_t,:])
    srcField = PF.BaseMag.SrcField([rxLoc_t], param=survey.srcField.param)
    survey_t = PF.BaseMag.LinearSurvey(srcField)
    survey_t.dobs = survey.dobs[ind_t]
    survey_t.std = survey.std[ind_t]

    # Extract model from global to local mesh
    if driver.topofile is not None:
        topo = np.genfromtxt(work_dir + driver.topofile,
                             skip_header=1)
        actv = Utils.surface2ind_topo(mesh_t, topo, 'N')
        actv = np.asarray(np.where(mkvc(actv))[0], dtype=int)
    else:
        actv = np.ones(mesh_t.nC, dtype='bool')

    nC = len(actv)
    
    # Create active map to go from reduce set to full
    actvMap = Maps.InjectActiveCells(mesh_t, actv, -100)
    
    # Creat reduced identity map
    idenMap = Maps.IdentityMap(nP=nC)
    
    # Create the forward model operator
    prob = PF.Magnetics.MagneticIntegral(mesh_t, chiMap=idenMap, actInd=actv)
    
    # Pair the survey and problem
    survey_t.pair(prob)
    
    # Create sensitivity weights from our linear forward operator
    
    wr = np.zeros(prob.F.shape[1])
    for ii in range(survey_t.nD):
        wr += (prob.F[ii, :]/survey_t.std[ii])**2.
    wr = wr**0.5
    wr = (wr/np.max(wr))
    
    
    # Create a regularization
    reg = Regularization.Sparse(mesh_t, indActive=actv, mapping=idenMap)
    reg.norms = driver.lpnorms
    
    if driver.eps is not None:
        reg.eps_p = driver.eps[0]
        reg.eps_q = driver.eps[1]
    
    reg.cell_weights = wr
    reg.mref = np.zeros(mesh_t.nC)[actv]
    
    # Data misfit function
    dmis = DataMisfit.l2_DataMisfit(survey_t)
    dmis.W = 1./survey_t.std
    
    # Add directives to the inversion
    opt = Optimization.ProjectedGNCG(maxIter=20, lower=0., upper=10.,
                                     maxIterLS=20, maxIterCG=10, tolCG=1e-4)
    invProb = InvProblem.BaseInvProblem(dmis, reg, opt)
    betaest = Directives.BetaEstimate_ByEig()
    
    # Here is where the norms are applied
    # Use pick a treshold parameter empirically based on the distribution of
    #  model parameters
    IRLS = Directives.Update_IRLS(f_min_change=1e-3, minGNiter=3, maxIRLSiter=10)
    update_Jacobi = Directives.Update_lin_PreCond()
    
    saveModel = Directives.SaveUBCModelEveryIteration(mapping=actvMap)
    saveModel.fileName = work_dir + out_dir + 'ModelSus'
    
    inv = Inversion.BaseInversion(invProb,
                                  directiveList=[betaest, IRLS, update_Jacobi,  saveModel])
    
    # Run the inversion
    m0 = np.ones(mesh_t.nC)[actv]*1e-4  # Starting model
    mrec = inv.run(m0)
    
    # Outputs
    Mesh.TensorMesh.writeUBC(mesh_t,work_dir + out_dir + tile_dirl2 + "MAG_Tile"+ str(tt) +".msh")
    Mesh.TensorMesh.writeUBC(mesh_t,work_dir + out_dir + tile_dirlp + "MAG_Tile"+ str(tt) +".msh")
    Mesh.TensorMesh.writeModelUBC(mesh_t,work_dir + out_dir + tile_dirl2 + "MAG_Tile"+ str(tt) +".sus", actvMap*reg.l2model)
    Mesh.TensorMesh.writeModelUBC(mesh_t,work_dir + out_dir + tile_dirlp + "MAG_Tile"+ str(tt) +".sus", actvMap*invProb.model)
    PF.Magnetics.writeUBCobs(work_dir+out_dir + tile_dirlp + "MAG_Tile"+ str(tt) +"_Inv.pre", survey_t, invProb.dpred)

#PF.Magnetics.plot_obs_2D(rxLoc,invProb.dpred,varstr='Amplitude Data')
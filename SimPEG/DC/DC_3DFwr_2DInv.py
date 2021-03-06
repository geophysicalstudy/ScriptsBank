"""
        Experimental script for the forward modeling of DC resistivity data
        along survey lines defined by the user. The program loads in a 3D mesh
        and model which is used to design pole-dipole or dipole-dipole survey
        lines.

        Uses SimPEG to generate the forward problem and compute the LU
        factorization.

        Calls DCIP2D for the inversion of a projected 2D section from the full
        3D model.

        Assumes flat topo for now...

        Created on Mon December 7th, 2015

        @author: dominiquef

"""


#%%
from SimPEG import *
import SimPEG.EM.Static.DC as DC
import pylab as plt
from pylab import get_current_fig_manager
from scipy.interpolate import griddata
import time
import re
import numpy.matlib as npm
import scipy.interpolate as interpolation
#==============================================================================
# from readUBC_DC3Dobs import readUBC_DC3Dobs
# from readUBC_DC2DModel import readUBC_DC2DModel
# from writeUBC_DCobs import writeUBC_DCobs

# from plot_pseudoSection import plot_pseudoSection
# from gen_DCIPsurvey import gen_DCIPsurvey
# from convertObs_DC3D_to_2D import convertObs_DC3D_to_2D
#==============================================================================
from matplotlib.colors import LogNorm
import os
import scipy.sparse as sp
import numpy as np

home_dir = 'C:\\Users\\DominiqueFournier\\ownCloud\\Research\\MtIsa\\Modeling'
#home_dir = 'C:\\Users\\dominiquef.MIRAGEOSCIENCE\\ownCloud\\Research\\Modelling\\Synthetic\\Two_Sphere'
dsep = '\\'
#from scipy.linalg import solve_banded

# Load UBC mesh 3D
#mesh = Mesh.TensorMesh.readUBC(home_dir + '\Mesh_5m.msh')
mesh = Mesh.TensorMesh.readUBC(home_dir + '\\MtIsa_20m.msh')
#mesh = Utils.meshutils.readUBCTensorMesh(home_dir + '\Mesh_50m.msh')

# Load model
model = Mesh.TensorMesh.readModelUBC(mesh,home_dir + '\\MtIsa_20m.con')
#model = Utils.meshutils.readUBCTensorModel(home_dir + '\Synthetic.con',mesh)
#model = Utils.meshutils.readUBCTensorModel(home_dir + '\Lalor_model_50m.con',mesh)
#model = Mesh.TensorMesh.readModelUBC(mesh,home_dir + '\TwoSpheres.con')

for pp in range(2):
    
    if pp == 1:
        model[model>1.25] = 0.08
        
    # Specify survey type
    stype = 'pdp'
    dtype = 'appc'
    
    # Survey parameters
    a = 100
    b = 50
    n = 8
    
    # Forward solver
    slvr = 'BiCGStab' #'LU'
    
    # Preconditioner
    pcdr = 'Jacobi'#
    
    # Inversion parameter
    pct = 0.01
    flr = 2e-4
    chifact = 1
    ref_mod = 5e-2
    str_mod = 5e-2
    # DOI threshold
    cutoff = 0.8
    
    # Plotting param
    vmin = -2.
    vmax = 1.
    zmax = 550. # Maximum depth to plot
    zmin = -25.
    xmax = 12650
    xmin = 11300
    dx = 20.
    
    #%% Create system
    #Set boundary conditions
    mesh.setCellGradBC('neumann')
    
    Div = mesh.faceDiv
    Grad = mesh.cellGrad
    Msig = Utils.sdiag(1./(mesh.aveF2CC.T*(1./model)))
    
    A = Div*Msig*Grad
    
    # Change one corner to deal with nullspace
    A[0,0] = 1
    A = sp.csc_matrix(A)
    
    start_time = time.time()
    
    if re.match(slvr,'BiCGStab'):
        # Create Jacobi Preconditioner
        if re.match(pcdr,'Jacobi'):
            dA = A.diagonal()
            P = sp.spdiags(1/dA,0,A.shape[0],A.shape[0])
    
            #LDinv = sp.linalg.splu(LD)
    
    elif re.match(slvr,'LU'):
        # Factor A matrix
        Ainv = sp.linalg.splu(A)
        print("LU DECOMP--- %s seconds ---" % (time.time() - start_time))
    
    #%% Create survey
    # Display top section
    top = int(mesh.nCz)-1
    
#    plt.figure()
#    ax_prim = plt.subplot(1,1,1)
#    dat1 = mesh.plotSlice(model, ind=top, normal='Z', grid=False, pcolorOpts={'alpha':0.5}, ax =ax_prim)
#    #==============================================================================
#    # plt.xlim([423200,423750])
#    # plt.ylim([546350,546650])
#    #==============================================================================
#    plt.gca().set_aspect('equal', adjustable='box')
#    
#    plt.show()
#    cfm1=get_current_fig_manager().window
    gin=[1]
    
    # Keep creating sections until returns an empty ginput (press enter on figure)
    #while bool(gin)==True:
    
    # Bring back the plan view figure and pick points
#    cfm1.activateWindow()
#    plt.sca(ax_prim)
    
    # Takes two points from ginput and create survey
    #if re.match(stype,'gradient'):
    #gin = [(423230.  ,  546440.), (423715.  ,  546440.)]
    #else:
    #gin = plt.ginput(2, timeout = 0)
    gin = [(11375, 12200), (12630, 12200)]
    
    
    #==============================================================================
    # if not gin:
    #     print 'SimPED - Simulation has ended with return'
    #     break
    #==============================================================================
    
    # Add z coordinate to all survey... assume flat
    nz = mesh.vectorNz
    var = np.c_[np.asarray(gin),np.ones(2).T*nz[-1]]
    
    # Snap the endpoints to the grid. Easier to create 2D section.
    indx = Utils.closestPoints(mesh, var )
    endl = np.c_[mesh.gridCC[indx,0],mesh.gridCC[indx,1],np.ones(2).T*nz[-1]]
    
    [survey, Tx, Rx] = DC.gen_DCIPsurvey(endl, mesh, stype, a, b, n)
    
    dl_len = np.sqrt( np.sum((endl[0,:] - endl[1,:])**2) )
    dl_x = ( Tx[-1][0,1] - Tx[0][0,0] ) / dl_len
    dl_y = ( Tx[-1][1,1] - Tx[0][1,0]  ) / dl_len
    azm =  np.arctan(dl_y/dl_x)
    
    # Plot stations along line
    plt.scatter(Tx[0][0,:],Tx[0][1,:],s=20,c='g')
    plt.scatter(Rx[0][:,0::3],Rx[0][:,1::3],s=20,c='y')
    
    #%% Forward model data
    data = []#np.zeros( nstn*nrx )
    unct = []
    problem = DC.ProblemDC_CC(mesh)
    
    tinf = np.squeeze(Rx[-1][-1,:3]) + np.array([dl_x,dl_y,0])*10*a
    
    for ii in range(len(Tx)):
        start_time = time.time()
    
        # Select dipole locations for receiver
        rxloc_M = np.asarray(Rx[ii][:,0:3])
        rxloc_N = np.asarray(Rx[ii][:,3:])
    
        # Number of receivers
        nrx = rxloc_M.shape[0]
    
    
    
        if not re.match(stype,'pdp'):
            inds = Utils.closestPoints(mesh, np.asarray(Tx[ii]).T )
            RHS = mesh.getInterpolationMat(np.asarray(Tx[ii]).T, 'CC').T*( [-1,1] / mesh.vol[inds] )
    
        else:
    
            # Create an "inifinity" pole
            tx =  np.squeeze(Tx[ii][:,0])
            
            inds = Utils.closestPoints(mesh, np.c_[tx].T)
            RHS = mesh.getInterpolationMat(np.c_[tx].T, 'CC').T*( [-1] / mesh.vol[inds] )
    
        # Solve for phi on pole locations
        P1 = mesh.getInterpolationMat(rxloc_M, 'CC')
        P2 = mesh.getInterpolationMat(rxloc_N, 'CC')
    
        if re.match(slvr,'BiCGStab'):
    
            if re.match(pcdr,'Jacobi'):
                dA = A.diagonal()
                P = sp.spdiags(1/dA,0,A.shape[0],A.shape[0])
    
                # Iterative Solve
                Ainvb = sp.linalg.bicgstab(P*A,P*RHS, tol=1e-5)
    
    
            phi = mkvc(Ainvb[0])
    
        elif re.match(slvr,'LU'):
            #Direct Solve
            phi = Ainv.solve(RHS)
    
    
    
        # Compute potential at each electrode
        dtemp = (P1*phi - P2*phi)*np.pi
    
        data.append( dtemp )
        unct.append( np.abs(dtemp) * pct + flr)
    
        print("--- %s seconds ---" % (time.time() - start_time))
    
    
    survey.dobs = np.hstack(data)
    survey.std = np.hstack(unct)
    #%% Run 2D inversion if pdp or dpdp survey
    # Otherwise just plot and apparent susceptibility map
    #if not re.match(stype,'gradient'):
    
    #%% Write data file in UBC-DCIP3D format
    DC.writeUBC_DCobs(home_dir+'\FWR_data3D.dat',survey,'3D','SURFACE')
    
    
    #%% Load 3D data
    #[Tx, Rx, data, wd] = DC.readUBC_DC3Dobs(home_dir + '\FWR_data3D.dat')
    
    
    #%% Convert 3D obs to 2D and write to file
    survey2D = DC.convertObs_DC3D_to_2D(survey,np.ones(survey.nSrc),flag = 'Xloc')
    
    DC.writeUBC_DCobs(home_dir+'\FWR_3D_2_2D.dat',survey2D,'2D','SURFACE')
    
    #%% Create a 2D mesh along axis of Tx end points and keep z-discretization
    dx = np.min( [ np.min(mesh.hx), np.min(mesh.hy) ])
    nc = np.ceil(dl_len/dx)+3
    
    padx = dx*np.power(1.4,range(1,12))
    
    # Creating padding cells
    h1 = np.r_[padx[::-1], np.ones(nc)*dx , padx]
    
    # Create mesh with 0 coordinate centerer on the ginput points in cell center
    x0 = np.min([gin[0][0],gin[1][0]]) - np.sum(padx) * np.cos(azm)
    y0 = np.min([gin[0][1],gin[1][1]]) - np.sum(padx) * np.sin(azm)
    mesh2d = Mesh.TensorMesh([h1, mesh.hz], x0=(x0,mesh.x0[2]))
    
    # Create array of points for interpolating from 3D to 2D mesh
    xx = x0 + (np.cumsum(mesh2d.hx) - mesh2d.hx/2) * np.cos(azm)
    yy = y0 + (np.cumsum(mesh2d.hx) - mesh2d.hx/2) * np.sin(azm)
    zz = mesh2d.vectorCCy
    
    [XX,ZZ] = np.meshgrid(xx,zz)
    [YY,ZZ] = np.meshgrid(yy,zz)
    
    xyz2d = np.c_[mkvc(XX),mkvc(YY),mkvc(ZZ)]
    
    #plt.scatter(xx,yy,s=20,c='y')
    
    
    F = interpolation.NearestNDInterpolator(mesh.gridCC,model)
    m2D = np.reshape(F(xyz2d),[mesh2d.nCx,mesh2d.nCy]).T
    
    
    #==============================================================================
    # mesh2d = Mesh.TensorMesh([mesh.hx, mesh.hz], x0=(mesh.x0[0]-endl[0,0],mesh.x0[2]))
    # m3D = np.reshape(model, (mesh.nCz, mesh.nCy, mesh.nCx))
    # m2D = m3D[:,1,:]
    #==============================================================================
    #%%
    
#    fig, ax = plt.subplots(1,1, figsize = (15,6))
#    
#    
#    #circle1=plt.Circle((144,1500),50,color='w',fill=False, lw=3)
#    #circle2=plt.Circle((344,1500),50,color='k',fill=False, lw=3)
#    #axs.add_artist(circle1)
#    #axs.add_artist(circle2)
#    #plt.pcolormesh(mesh2d.vectorNx,mesh2d.vectorNy,np.log10(m2D))#axes = [mesh2d.vectorNx[0],mesh2d.vectorNx[-1],mesh2d.vectorNy[0],mesh2d.vectorNy[-1]])
#    dat = mesh.plotSlice(np.log10(model), normal = 'Y', ind=int(mesh.vnN[1]/2), ax=ax, clim=(vmin, vmax), grid=False, gridOpts={"alpha":0.2})
#    cbar = fig.colorbar(dat1[0],cax=ax, orientation="horizontal", ax = ax, ticks=np.linspace(vmin, vmax, 4), format="$10^{%.1f}$")
#    cmin,cmax = cbar.get_clim()
#    ticks = np.linspace(cmin,cmax,3)
#    cbar.set_ticks(ticks)
#    
#    # Plot poles
#    plt.scatter(survey2D.srcList[0].loc[0][0],survey2D.srcList[0].loc[0][2]+dx,s=50,c='r',marker='v')
#    plt.scatter(survey2D.srcList[0].loc[1][0],survey2D.srcList[0].loc[1][2]+dx,s=50,c='b',marker='v')
#    plt.scatter(survey2D.srcList[0].rxList[0].locs[0][:,0],survey2D.srcList[0].rxList[0].locs[0][:,2]+dx,s=50,c='g')
#    #mesh2d.plotImage(mkvc(m2D), grid=True, ax=axs)
#    plt.gca().set_aspect('equal', adjustable='box')
#    plt.xlim([xmin,xmax])
#    plt.ylim([zmin,zmax])
    
    
    #%% Plot pseudo section
#    fig, ax = plt.subplots(1,1, figsize = (15,6))
#    
#    #circle1=plt.Circle((144,1500),50,color='w',fill=False, lw=3)
#    #circle2=plt.Circle((344,1500),50,color='k',fill=False, lw=3)
#    #axs.add_artist(circle1)
#    #axs.add_artist(circle2)
#    
#    ph = DC.plot_pseudoSection(survey2D,ax,stype, dtype = dtype, clim = [vmin,vmax])
#    plt.gca().set_aspect('equal', adjustable='box')
#    plt.xlim([survey2D.srcList[0].loc[0][0]-a,survey2D.srcList[-1].rxList[-1].locs[-1][0][0]+a])
#    plt.ylim([mesh2d.vectorNy[-1]-dl_len/2,mesh2d.vectorNy[-1]+2*dx])
#    #ax.set_xlabel('Easting (m)')
#    plt.show()
    
    #%% Run two inversions with different reference models and compute a DOI
    
    #invmod = []
    #refmod = []
    #plt.figure()
    
    #for jj in range(2):
    
    # Create dcin2d inversion files and run
    inv_dir = home_dir + '\Inv2D'
    if not os.path.exists(inv_dir):
        os.makedirs(inv_dir)
    
    mshfile2d = 'Mesh_2D.msh'
    modfile2d = 'Model_2D.con'
    obsfile2d = 'FWR_3D_2_2D.dat'
    inp_file = 'dcinv2d.inp'
    
    
    # Export 2D mesh
    fid = open(inv_dir + dsep + mshfile2d,'w')
    fid.write('%i\n'% mesh2d.nCx)
    fid.write('%f %f 1\n'% (mesh2d.vectorNx[0],mesh2d.vectorNx[1]))
    np.savetxt(fid, np.c_[mesh2d.vectorNx[2:],np.ones(mesh2d.nCx-1)], fmt='\t %e %i',delimiter=' ',newline='\n')
    fid.write('\n')
    fid.write('%i\n'% mesh2d.nCy)
    fid.write('%f %f 1\n'%( 0,mesh2d.hy[-1]))
    np.savetxt(fid, np.c_[np.cumsum(mesh2d.hy[-2::-1])+mesh2d.hy[-1],np.ones(mesh2d.nCy-1)], fmt='\t %e %i',delimiter=' ',newline='\n')
    fid.close()
    
    # Export 2D model
    fid = open(inv_dir + dsep + modfile2d,'w')
    fid.write('%i %i\n'% (mesh2d.nCx,mesh2d.nCy))
    np.savetxt(fid, mkvc(m2D[::-1,:].T), fmt='%e',delimiter=' ',newline='\n')
    fid.close()
    
    # Export data file
    DC.writeUBC_DCobs(inv_dir+dsep+obsfile2d,survey2D,'2D','SIMPLE')
    
    # Write input file
    fid = open(inv_dir + dsep + inp_file,'w')
    fid.write('OBS LOC_X %s \n'% obsfile2d)
    fid.write('MESH FILE %s \n'% mshfile2d)
    fid.write('CHIFACT 1 %f\n'% chifact)
    fid.write('TOPO DEFAULT  %s \n')
    fid.write('INIT_MOD VALUE %e\n'% (str_mod))
    fid.write('REF_MOD VALUE %e\n'% (ref_mod))
    fid.write('ALPHA VALUE %f %f %F\n'% (1./dx**4., 1, 3))
    fid.write('WEIGHT DEFAULT\n')
    fid.write('STORE_ALL_MODELS FALSE\n')
    fid.write('INVMODE CG\n')
    fid.write('USE_MREF TRUE\n')
    fid.close()
    
    os.chdir(inv_dir)
    os.system('dcinv2d ' + inp_file)
    
    
    #Load model
    minv = DC.readUBC_DC2DModel(inv_dir + dsep + 'dcinv2d.con')
    
    #%% Compute DOI
    #    DOI = np.abs(invmod[0] - invmod[1]) / np.abs(refmod[0] - refmod[1])
    #    # Normalize between [0 1]
    #    DOI = DOI - np.min(DOI)
    #    DOI = (1.- DOI/np.max(DOI))
    #    DOI[DOI > cutoff] = 1
    #
    #    plt.figure()
    #    plt.xlim([survey2D.srcList[0].loc[0][0]-a,survey2D.srcList[-1].rxList[-1].locs[-1][0][0]+a])
    #    plt.ylim([mesh2d.vectorNy[-1]-dl_len/2,mesh2d.vectorNy[-1]+2*dx])
    #    plt.gca().set_aspect('equal', adjustable='box')
    #
    #    plt.pcolormesh(mesh2d.vectorNx,mesh2d.vectorNy,DOI,alpha=1)
    #    cbar = plt.colorbar(format = '%.2f',fraction=0.02)
    
    #%% Replace alpha values from inversion
    #rgba_plt = axp.get_facecolor()
    #rgba_plt[:,3] = mkvc(DOI)/2
    
    if pp == 0:
        fig1 = plt.figure(figsize=(7,7))
    
    
    ax = fig1.add_subplot(2,1,pp+1, aspect='equal')  
    
    if pp == 1:
        pos =  ax.get_position() 
        ax.set_position([pos.x0, pos.y0-.1,  pos.width, pos.height])
        
    minv = np.reshape(minv,(mesh2d.nCy,mesh2d.nCx))
    ax.pcolor(mesh2d.vectorNx,mesh2d.vectorNy,np.log10(m2D),edgecolor="none",alpha=0.5,cmap = 'gray')
    pc = ax.pcolor(mesh2d.vectorNx,mesh2d.vectorNy,np.log10(minv),edgecolor="none",alpha=0.5)

    if pp == 0:
        
        circle=plt.Circle((12000,135),100,color='k',fill=False, lw=3)
        ax.add_artist(circle)

#    cbar = plt.colorbar(format="$10^{%.1f}$",fraction=0.04,orientation="horizontal")
#    cmin,cmax = cbar.get_clim()
#    ticks = np.linspace(cmin,cmax,3)
#    cbar.set_ticks(ticks)
#    cbar.ax.tick_params(labelsize=10)
#    cbar.set_label("S/m",size=12)
    #ax.set_title('2-D model')
    
    if pp == 0:
        ax.get_xaxis().set_ticks([])
    
    ax.set_xlim([xmin,xmax])
    ax.set_ylim([zmin,zmax])
    plt.gca().set_aspect('equal', adjustable='box')
    plt.show()
    
    if pp == 0:
        pos =  ax.get_position() 
        cbarax = fig1.add_axes([pos.x0+.2, pos.y0-.025,  pos.width*0.5, pos.height*0.05])  ## the parameters are the specified position you set 
        cb = plt.colorbar(pc, cax=cbarax, orientation="horizontal", ax = ax, ticks=np.linspace(-2.5,-0.5, 4), format="$10^{%.1f}$")
        cb.set_label("Conductivity (S/m)",size=12)
        #ax.set_title('2-D Conductivity Model')
        
    if pp == 0:
        fig2 = plt.figure(figsize=(7,7))
        
    # Second plot for the predicted apparent resistivity data
    ax2 = fig2.add_subplot(2,1,pp+1, aspect='equal')
        
    ax2.pcolor(mesh2d.vectorNx,mesh2d.vectorNy,np.log10(m2D),edgecolor="none",alpha=0.5,cmap = 'gray')
    # Add the speudo section
    dat = DC.plot_pseudoSection(survey2D,ax2,stype=stype, clim=[-2.5,-0.5], dtype = dtype)
    
    if pp == 0:
    
        circle=plt.Circle((12000,135),100,color='k',fill=False, lw=3)
        ax2.add_artist(circle)
        
    ax2.set_xlim([xmin,xmax])
    ax2.set_ylim([zmin,zmax])
    plt.show()
    
    if pp == 0:
        ax2.get_xaxis().set_ticks([])
    
#    pos =  ax2.get_position()
#    pos = ax2.set_position([pos.x0 , pos.y0+0.075,  pos.width, pos.height])
    
    if pp == 1:
#        pos =  ax.get_position() 
        cbarax = fig2.add_axes([pos.x0+.2, pos.y0-.025,  pos.width*0.5, pos.height*0.05])  ## the parameters are the specified position you set 
        cbar = plt.colorbar(dat,cax=cbarax, ax = ax2,orientation="horizontal",ticks=np.linspace(-2.5,-0.5, 4), format="$10^{%.1f}$")
        cbar.set_label("Apparent Conductivity (S/m)",size=12)
    
    plt.show()

    #%% Add labels
    A = [survey.srcList[0].loc[0][0], survey.srcList[0].loc[0][2]]
    M = [survey.srcList[0].rxList[0].locs[0][0,0], survey.srcList[0].rxList[0].locs[0][0,2]]
    N = [survey.srcList[0].rxList[0].locs[1][0,0], survey.srcList[0].rxList[0].locs[1][0,2]]
    
    bbox_props = dict(boxstyle="circle,pad=0.3",fc="r", ec="k", lw=1)
    ax2.text(A[0],A[1], 'A', ha="left", va="center",
                size=10,
                bbox=bbox_props)
    
    bbox_props = dict(boxstyle="circle,pad=0.3",fc="y", ec="k", lw=1)
    ax2.text(M[0],M[1], 'M', ha="left", va="center",
                size=10,
                bbox=bbox_props)
    
    bbox_props = dict(boxstyle="circle,pad=0.3",fc="g", ec="k", lw=1)
    ax2.text(N[0],N[1], 'N',  ha="left", va="center",
                size=10,
                bbox=bbox_props)
    
    # Add line linking the symbols to data
    midMN = (M[0] + N[0])/2
    midAMN = (midMN + A[0] ) /2
    midz = A[1] - (midAMN - A[0])
    plt.plot([A[0],midAMN],[A[1],midz],'k--')
    plt.plot([midMN,midAMN],[M[1],midz],'k--')

#    pos =  ax2.get_position()
#    cbarax = fig.add_axes([pos.x0+0.19 , pos.y0-0.05,  pos.width*0.5, pos.height*0.05])  ## the parameters are the specified position you set
#    cb = fig.colorbar(dat,cax=cbarax, orientation="horizontal", ax = ax2, ticks=np.linspace(-2,-0.5, 4), format="$10^{%.1f}$")
#    cb.set_label("Conductivity (S/m)",size=12)
#    plt.draw()


#%% Othrwise it is a gradient array, plot surface of apparent resisitivty
#elif re.match(stype,'gradient'):
#
#    rC1P1 = np.sqrt( np.sum( (npm.repmat(Tx[0][0:2,0],Rx[0].shape[0], 1) - Rx[0][:,0:2])**2, axis=1 ))
#    rC2P1 = np.sqrt( np.sum( (npm.repmat(Tx[0][0:2,1],Rx[0].shape[0], 1) - Rx[0][:,0:2])**2, axis=1 ))
#    rC1P2 = np.sqrt( np.sum( (npm.repmat(Tx[0][0:2,1],Rx[0].shape[0], 1) - Rx[0][:,3:5])**2, axis=1 ))
#    rC2P2 = np.sqrt( np.sum( (npm.repmat(Tx[0][0:2,0],Rx[0].shape[0], 1) - Rx[0][:,3:5])**2, axis=1 ))
#
#    rC1C2 = np.sqrt( np.sum( (npm.repmat(Tx[0][0:2,0]-Tx[0][0:2,1],Rx[0].shape[0], 1) )**2, axis=1 ))
#    rP1P2 = np.sqrt( np.sum( (Rx[0][:,0:2] - Rx[0][:,3:5])**2, axis=1 ))
#
#    rho = np.abs(data[0]) * np.pi *((rC1P1)**2 / rP1P2)#/ ( 1/rC1P1 - 1/rC2P1 - 1/rC1P2 + 1/rC2P2 )
#
#    Pmid = (Rx[0][:,0:2] + Rx[0][:,3:5])/2
#
#    # Grid points
#    grid_x, grid_z = np.mgrid[np.min(Rx[0][:,[0,3]]):np.max(Rx[0][:,[0,3]]):a/10, np.min(Rx[0][:,[1,4]]):np.max(Rx[0][:,[1,4]]):a/10]
#    grid_rho = griddata(np.c_[Pmid[:,0],Pmid[:,1]], (abs(rho.T)), (grid_x, grid_z), method='linear')
#
#
#    #plt.subplot(2,1,2)
#    plt.imshow(grid_rho.T, extent = (np.min(grid_x),np.max(grid_x),np.min(grid_z),np.max(grid_z))  ,origin='lower')
#    var = 'Gradient Array - a-spacing: ' + str(a) + ' m'
#    plt.title(var)
#    plt.colorbar()

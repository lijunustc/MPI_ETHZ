        program heat
        parameter (imax=80,kmax=80)
        parameter (itmax=20000)
        double precision eps
        parameter (eps=1.d-08)
        double precision phi(0:imax,0:kmax), phin(1:imax-1,1:kmax-1)
        double precision dx,dy,dx2,dy2,dx2i,dy2i,dt,dphi,dphimax
        real tarray(2)
c
        dx=1.d0/kmax
        dy=1.d0/imax
        dx2=dx*dx
        dy2=dy*dy
        dx2i=1.d0/dx2
        dy2i=1.d0/dy2
        dt=min(dx2,dy2)/4.d0
c start values 0.d0
        do k=0,kmax-1
         do i=1,imax-1
           phi(i,k)=0.d0
         enddo
        enddo
c start values 1.d0
        do i=0,imax
         phi(i,kmax)=1.d0
        enddo
c start values dx
        phi(0,0)=0.d0
        phi(imax,0)=0.d0
        do k=1,kmax-1
         phi(0,k)=phi(0,k-1)+dx
         phi(imax,k)=phi(imax,k-1)+dx
        enddo
c print array
        write (*,'(/,a)')
     f  'Heat Conduction 2d'
        write (*,'(/,4(a,1pg12.4))')
     f  'dx =',dx,', dy =',dy,', dt =',dt,', eps =',eps
        t0=dtime(tarray)
c iteration
        do it=1,itmax
         dphimax=0.
         do k=1,kmax-1
          do i=1,imax-1
            dphi=(phi(i+1,k)+phi(i-1,k)-2.*phi(i,k))*dy2i
     f           +(phi(i,k+1)+phi(i,k-1)-2.*phi(i,k))*dx2i
            dphi=dphi*dt
            dphimax=max(dphimax,dphi)
            phin(i,k)=phi(i,k)+dphi
          enddo
         enddo
c save values
         do k=1,kmax-1
          do i=1,imax-1
           phi(i,k)=phin(i,k)
          enddo
         enddo
         if(dphimax.lt.eps) goto 10
        enddo
10      continue
        t1=dtime(tarray)
c print array
        write (*,'(/,a,i6,a)')
     f  'phi after',it,' iterations'
        write (*,'(/,2(a,1pg12.4,/))')
     f  'user time   = ', tarray(1),
     f  'system time = ', tarray(2)
        stop
        end

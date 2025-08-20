import os
import sys
srcpath = os.path.realpath('../SourceFiles')
sys.path.append(srcpath)

import numpy as np
import time
import ipywidgets as widgets
from IPython.core.debugger import set_trace
from scipy.signal import chirp, sweep_poly
import matplotlib.pyplot as plt
from matplotlib.widgets import Button, RadioButtons, CheckButtons
import keyboard

% arb_type='lan' % pxi or lan
arb_type='pxi' % pxi or lan


if(arb_type=='pxi'):
    print("PXI Inst")
    from teproteus import TEProteusAdmin as TepAdmin
    from teproteus import TEProteusInst as TepInst
%      Connect to instrument
    admin = TepAdmin();
    inst = admin.open_instrument(slot_id=4);
else:
    print("LAN Visa Inst")
    from tevisainst import TEVisaInst
%     inst_addr = 'TCPIP::127.0.0.1::5025::SOCKET'  #<- AWG address
%     inst_addr = 'TCPIP::192.168.71.1::5025::SOCKET'  #<- AWG address
    inst_addr = 'TCPIP::192.168.0.202::5025::SOCKET'  %<- AWG address
    inst = TEVisaInst(inst_addr);

paranoia_level = 1;
sampleRateDAC = 1E9;

% Get the instrument's *IDN
resp = inst.send_scpi_query('*IDN?';)
print(resp)

inst.send_scpi_cmd(":INST:CHAN 1")
inst.send_scpi_cmd(':OUTP OFF')
inst.send_scpi_cmd(':FUNC:MODE ARB')
inst.send_scpi_cmd(':TRAC:DEL:ALL')
inst.send_scpi_cmd(':TASK:ZERO:ALL')

inst.send_scpi_cmd("*CLS; *RST")

inst.send_scpi_cmd(":FREQ:RAST {0}".format(sampleRateDAC))
inst.send_scpi_cmd(":INIT:CONT ON")

sclk = inst.send_scpi_query(":FREQ:RAST?");
print("Sample Clk: " + sclk + "MHz")

dac_res = 16;
max_dac = 2 ** dac_res - 1;
half_dac = max_dac / 2.0;
data_type = np.uint16;

%  Define and scale to DAC segment 1 of channel 1
segnum = 1;
amp = 1;    
segLen = 2048;
cycles = 10;
time = np.linspace(0, segLen-1, segLen);
omega = 2 * np.pi * cycles;
dacWave = (amp*(np.sin(omega*time/segLen)) + 1.0) * half_dac;
dacWave = np.round(dacWave);
dacWave = np.clip(dacWave, 0, max_dac);
dacWave_1 = dacWave.astype(data_type);

% Download it to segment 1 of channel 1
inst.send_scpi_cmd(":INST:CHAN 1") 
inst.send_scpi_cmd( ":TRAC:DEF 1," + str(len(dacWave_1)), paranoia_level)
inst.send_scpi_cmd( ":TRAC:SEL 1", paranoia_level)

inst.write_binary_data(':TRAC:DATA', dacWave_1)
resp = inst.send_scpi_query(':SYST:ERR?');
print(resp)

%  Play the specified segment at the selected channel:
cmd = ':SOUR:FUNC:MODE:SEGM {0}'.format(segnum)
rc = inst.send_scpi_cmd(cmd);

%  Define and scale to DAC segment 2 of channel 1
segnum = 2;
amp = 1;    
segLen = 2048;
cycles = 5;
omega = 2 * np.pi * cycles;
dacWave = (amp*(np.sin(omega*time/segLen)) + 1.0) * half_dac;
dacWave = np.round(dacWave);
dacWave = np.clip(dacWave, 0, max_dac);
dacWave_2 = dacWave.astype(data_type);

%  Download it to segment 2 of channel 1
inst.send_scpi_cmd(":INST:CHAN 1") 
inst.send_scpi_cmd( ":TRAC:DEF 2," + str(len(dacWave_2)), paranoia_level)
inst.send_scpi_cmd( ":TRAC:SEL 2", paranoia_level)

inst.write_binary_data(':TRAC:DATA', dacWave_2)
resp = inst.send_scpi_query(':SYST:ERR?');
print(resp)

%  Play the specified segment at the selected channel:
% cmd = ':SOUR:FUNC:MODE:SEGM {0}'.format(segnum)
% rc = inst.send_scpi_cmd(cmd)

%  The Task Composer is configured to handle a certain number of task entries
inst.send_scpi_cmd(':TASK:COMP:LENG 2'); 

% Task 1, play seg 1 goto task 2
inst.send_scpi_cmd(':TASK:COMP:SEL 1');
inst.send_scpi_cmd(':TASK:COMP:SEGM 1'); 
inst.send_scpi_cmd(':TASK:COMP:ENAB TRG1');
% inst.send_scpi_cmd('::TASK:COMP:DTR ON');
inst.send_scpi_cmd(':TASK:COMP:NEXT1 2');

%  Task 1, play seg 2 goto task 1
inst.send_scpi_cmd(':TASK:COMP:SEL 2');
inst.send_scpi_cmd(':TASK:COMP:SEGM 2');
inst.send_scpi_cmd(':TASK:COMP:ENAB TRG1');
% inst.send_scpi_cmd('::TASK:COMP:DTR ON');
inst.send_scpi_cmd(':TASK:COMP:NEXT1 1');

%  write task table
inst.send_scpi_cmd(':TASK:COMP:WRIT');
print('SEQUENCE CREATED!\n');

inst.send_scpi_cmd(':FUNC:MODE TASK');

% DO I NEED THIS??
inst.send_scpi_cmd(':TRIG:ACTIVE:SEL TRG1'); 
inst.send_scpi_cmd(':TRIG:ACTIVE:STAT ON');

inst.send_scpi_cmd(':OUTP ON')

if(arb_type=='pxi'):
    inst.close_instrument()
    admin.close_inst_admin()
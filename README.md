# overtones
overtones is a script based on additive synthesis. it’s easy to program and made for atmospheric, evolving digital soundscapes and other types of artificial sounds. there are 8 partials and 4 snapshots. each snapshot contains a complete waveform, and they are morphed into each other using 3 different methods. the user interface has 5 sections of parameters. use k2 and k3 to step through them.

a midi keyboard is required for this script. a grid and/or midi controller is optional. midi in device and channel can be set in parameters>edit.

section 1:  
![](overtones_section1.png)  
this is where waveforms are created. use e1 to select 1 of 4 snapshots which are represented by the empty boxes in the middle of the screen. the selected snapshot is filled. use e2 to move the cursor at the bottom which selects 1 of the 8 partials to edit. use e3 to adjust the volume of the selected partial.

k1 + k2 will copy the currently selected snapshot. k1 + k3 will paste it into another selected snapshot. the memory will be overwritten if another snapshot is copied and deleted if the script has been reloaded.

tip:  
the snapshot remains in memory even after another pset has been loaded. this makes it possible to transfer a waveform from one pset to another.

section 2:  
![](overtones_section2.png)  
these are the morph parameters. the arrows show the start (left) and end (right) point while the dimly lit boxes represent the snapshots. use e2 to select a parameter to edit and e3 to adjust it. *“start”* sets the beginning of the morph. *“end”* sets either the turning point of the morph or the end of it depending on the next parameter. *“l>r>e”* stands for *“(l)fo to (r)andom to (e)nvelope”*. the *“lfo”* morphs from the start to the end point and then back again in reversed order continuously, *“random”* morphs randomly within the set range and the *“envelope”* morphs from the start to the end point where it stays for as long as a note is sustained. *“rate”* sets the speed of the morph. use e1 to adjust the main volume (a pop-up screen will show the value).

tip 1:  
setting the start and end point in the opposite direction will reverse the morph. this is probably only useful when the envelope is selected as the morph method.

tip 2:  
setting the start and end parameter to the same point will freeze the morph. this could be useful for drones.

section 3:  
![](overtones_section3.png)  
the adsr envelope controls the overall volume. use e2 to select a parameter and e3 to adjust it. use e1 to adjust the main volume.

section 4:  
![](overtones_section4.png)  
*“width”* spreads out the partials in the stereo field. they are constantly panned randomly, and *“rate”* sets the speed. *“w&f”* adds random pitch fluctuations and sets the modulation depth. *“rate”* sets the speed. use e2 to select a parameter and e3 to adjust it. use e1 to adjust the main volume.

section 5:  
![](overtones_section5.png)  
this section shows all 4 snapshots on the same screen. all tools that are available in section 1 are here as well, including the possibility to copy and paste snapshots. the first number in the top right corner shows the selected snapshot, the second the partial and the third below the others the volume. the circle marks the selected partial.

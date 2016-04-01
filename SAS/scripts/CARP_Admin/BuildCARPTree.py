'''
Created on Jun 10, 2011

@author: dpressley
'''

'''
Created on Apr 6, 2011
Create the minimal working copy directory tree structure
@author: dpressley
'''
import os

trial = raw_input("Enter the project's trial name (8 or 10 digit): ")
trial = trial.upper()


therapeutic_area = trial[:3]

username = os.getenv('USERNAME')

basepath = os.path.join(os.path.join("C:\\Users",username),"Projects")
fo_basepath = "S:\\Stat Programming\Projects" 
print "Final Output Basepath: " + fo_basepath



if (len(trial) == 0):
    if not os.path.exists(basepath):
        print "Your username needs to be created. Please enter a support ticket"
   
elif (len(trial)==10):
    if ((trial[3]=="-") and (trial[6]=="-")):   
        indication = trial[4:6]
        studynumber = trial[7:]
        trial = therapeutic_area+indication+studynumber
            
fo_trial = os.path.join(os.path.join(fo_basepath,therapeutic_area),trial)

    

print "BasePath= " + basepath 
print "trial: " + trial
print "TherapeuticArea: " + therapeutic_area
#trial = os.makedirs(os.path.join(os.path.join(basepath,therapeutic_area),trial),0777)

    
try:    
    trial = os.path.join(os.path.join(basepath,therapeutic_area),trial)
    os.makedirs(trial)
    if os.path.exists(trial):
        print "Path: " + trial +" created successfully"
except IOError,e:
    print e
except WindowsError, e:
    print "Folder structure already exists"
    print e

try:           
    data = os.path.join(trial,os.path.join("data","intermed"))
    os.makedirs(data, 0777)
    if os.path.exists(data):
        print "Path: " + data +" created successfully"
except IOError,e:
    print e
except WindowsError, e:
    print "Folder structure already exists"
    print e
         
try: 
    documents = os.path.join(trial,"documents")
    os.makedirs(documents, 0777)
    if os.path.exists(documents):
        print "Path: " + documents +" created successfully"
except IOError,e:
    print e
except WindowsError, e:
    print "Folder structure already exists"
    print e
    
try:    
    tags = os.path.join(trial,"tags")
    os.makedirs(tags, 0777)
    if os.path.exists(tags):
        print "Path: " + tags +" created successfully"
except IOError,e:
    print e
except WindowsError, e:
    print "Folder structure already exists"
    print e
    
try:        
    output = os.path.join(trial,"output")
    os.makedirs(output, 0777)
    if os.path.exists(output):
        print "Path: " + output +" created successfully"
except IOError,e:
    print e
except WindowsError, e:
    print "Folder structure already exists"
    print e
    
try:        
    draft = os.path.join(output,"draft")
    os.makedirs(draft, 0777)
    if os.path.exists(draft):
        print "Path: " + draft +" created successfully"
except IOError,e:
    print e
except WindowsError, e:
    print "Folder structure already exists"
    print e
    
try:        
    finaloutput = os.path.join(fo_trial,"output")
    final = os.path.join(finaloutput,"final")
    os.makedirs(final, 0777)
    if os.path.exists(final):
        print "Path: " + final +" created successfully"
except IOError,e:
    print e
except WindowsError, e:
    print "Folder structure already exists"
    print e
    
try:      
    programs = os.path.join(trial,"programs")
    os.makedirs(programs, 0777)
    if os.path.exists(programs):
        print "Path: " + programs +" created successfully"
except IOError,e:
    print e
except WindowsError, e:
    print "Folder structure already exists"
    print e
    
try:        
    csr = os.path.join(programs,"csr")
    os.makedirs(csr, 0777)
    if os.path.exists(csr):
        print "Path: " + csr +" created successfully"
except IOError,e:
    print e
except WindowsError, e:
    print "Folder structure already exists"
    print e
    
try:        
    data = os.path.join(programs,"data")
    os.makedirs(data, 0777)
    if os.path.exists(data):
        print "Path: " + data +" created successfully"
except IOError,e:
    print e
except WindowsError, e:
    print "Folder structure already exists"
    print e
    
try:        
    qc = os.path.join(programs,"QC")
    os.makedirs(qc, 0777)
    if os.path.exists(qc):
        print "Path: " + qc +" created successfully"
except IOError,e:
    print e
except WindowsError, e:
    print "Folder structure already exists"
    print e

try:       
    wip = os.path.join(programs,"wip")
    os.makedirs(wip, 0777)
    if os.path.exists(wip):
        print "Path: " + wip +" created successfully"
except IOError,e:
    print e
except WindowsError, e:
    print "Folder structure already exists"
    print e    


raw_input("Press return to close this window...")

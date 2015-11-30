import csv
from py2neo import authenticate, Graph
 
 
def graphExecute(cmd):
    ''' @summary: I am really lazy and just didn't want to run through a lot of
            try statements.
    '''
    try:
        graph.cypher.execute(cmd)
    except:
        pass
 
#Establishing connection
authenticate('localhost:7474', 'neo4j', 'abc123!!!')
graph = Graph()
 
 
try:
    graph.schema.create_uniqueness_constraint('User', 'samAccountName')
    graph.schema.create_uniqueness_constraint('PrivyUser', 'samAccountName')
    graph.schema.create_uniqueness_constraint('Computer', 'name')
    graph.schema.create_uniqueness_constraint('CriticalComputer', 'name')
    graph.schema.create_uniqueness_constraint('DefaultGateway', 'ip')
except:
    pass #already been initialized
 
tx = graph.cypher.begin()
 
 
#Reading in privyUsers from powershell csv
privyUsers = []
 
with open('privUsersReal.csv', 'rb') as csvfile:
    data = csv.reader(csvfile)
    for row in data:
        privyUsers.append(row[0].lower())
 
#Getting non privy 
nonprivyUsers = {}
 
 
with open('nonprivyusers.csv', 'rb') as csvfile:
    data = csv.reader(csvfile)
    for row in data:
        nonprivyUsers[row[0].lower()] = row[1]
         
#Reading in SCCM query csv
sccm = []
 
 
with open('sccmquery.csv', 'rb') as csvfile:
    data = csv.reader(csvfile)
    for row in data:
        sccm.append('|'.join(row))
 
#iterating through each row from SCCM output
for row in sccm:
    data = row.split('|')
    topUser = data[0].split('\\')[-1].lower()
    primaryUser = data[1].lower()
    comp = data[2].lower()
    ips = data[3].split(',')
    gw = data[4]
     
    #Trying to find an ipv4 address
    for i in ips:
        try:
            socket.inet_aton(i)
        except socket.error:
            continue
        else:
            ip = i
            break
     
    try:
        ip
    except NameError:
        continue #Could not find a valid ipv4 address, as of now that makes this useless to me
     
    defaultGateway.properties['name'] = "Default Gateway"
    node_comp = 'Computer'
     
    if topUser in privyUsers:
        node_tuser = 'PrivyUser'
        node_comp = 'CriticalComputer'
    else:
        node_tuser = 'User'
         
    try:
        topUserName = nonprivyUsers[topUser]
    except KeyError:
        topUserName = 'unknown'
             
    if primaryUser in privyUsers:
        node_puser = 'PrivyUser'
        node_comp = 'CriticalComputer'
    else:
        node_puser = 'User'
     
    try:
        pUserName = nonprivyUsers[primaryUser]
    except KeyError:
        pUserName = 'unknown'
         
    #building nodes and relationships
    graphExecute("MERGE (a:DefaultGateway {ip: '%s', name: 'Default Gateway'})" %(gw))
    graphExecute("MERGE (a:%s {ip: '%s', name: '%s', gw: '%s'})" %(node_comp, ip, comp, gw))
    graphExecute("MERGE (a:%s {samAccountName: '%s', name: '%s'})" %(node_tuser, topUser, topUserName))
     
    if primaryUser != 'null':
        graphExecute("MERGE (a:%s {samAccountName: '%s', name: '%s'})" %(node_puser, primaryUser, pUserName))
        graph.cypher.execute("MATCH (a:%s { name: '%s' }), (b:%s { samAccountName: '%s' }) CREATE UNIQUE (b)-[:PRIMARY_USER]->(a)" %(node_comp, comp, node_puser, primaryUser))
     
    graph.cypher.execute("MATCH (a:%s { name: '%s' }), (b:%s { samAccountName: '%s' }) CREATE UNIQUE (b)-[:TOP_USER]->(a)" %(node_comp, comp, node_tuser, topUser))
    graph.cypher.execute("MATCH (a:%s { name: '%s' }), (b:DefaultGateway { ip: '%s' }) CREATE UNIQUE (a)-[:CONNECTED]->(b)" %(node_comp, comp, gw))

sccm2 = []
with open('sccmquery2.csv', 'rb') as csvfile:
    data = csv.reader(csvfile)
    for row in data:
        sccm2.append('|'.join(row))
         
for row in sccm2:
    data = row.split('|')
    comp = data[0].lower()
    user = data[1].split('\\')[-1].lower()
    date = data[2]
     
    if user in privyUsers:
        node_user = 'PrivyUser'
        node_comp = 'CriticalComputer'
    else:
        node_user = 'User'
        node_comp = 'Computer'
     
    try:
        topUserName = nonprivyUsers[user]
    except KeyError:
        topUserName = 'unknown'
         
    #building nodes and relationships
    graphExecute("MERGE (a:%s {ip: '%s', name: '%s', gw: '%s'})" %(node_comp, comp))
    graphExecute("MERGE (a:%s {samAccountName: '%s', name: '%s'})" %(node_user, user, topUserName))
    graph.cypher.execute("MATCH (a:%s { name: '%s' }), (b:%s { samAccountName: '%s' }) CREATE (b)-[:LOGGED_INTO_%s]->(a)" %(node_comp, comp, node_user, user, date))
    

from flask import Flask
import socket
import json
from flask import render_template, url_for

app = Flask(__name__)
  
g_port = 8891  
    
@app.route('/skynet/<int:port>/<method>')
def hello_static(port, method):
    global g_port
    g_port = port
    print('port:', port)
    return render_template('lui.html', method=method)
    
    
    
    
@app.route('/skynet_inner/<cmd>')
def skynet_cmd(cmd):
    sc = socket.socket()         
    host = '127.0.0.1'          
    global g_port
    sc.connect((host, g_port))   
    sc.settimeout(5)

    sc.send(cmd + '\n')
    str_html = ''
    str_raw = ''
    endstr = ['<CMD OK>\n', '<CMD Error>\n']
    while True:
        content = sc.recv(1024)
        #print(content)
        str_raw += content
        recv_over = False
        for s in endstr:
            if content[-1 * len(s):] == s:
                recv_over = True
                break
                
        content = content.replace('\n', '<br/>')
        str_html += content
        if recv_over:
            break
        
    sc.close()
    if cmd == 'list':
        return process_list(str_raw)
    elif cmd == 'mem':
        return process_mem(str_raw) 
        
    
    
def process_list(str):
    print(str)
    lines = str.split('\n')
    newlines = [val for i, val in enumerate(lines) if len(val) > 0 and val[0] == ':' ]
    #print(newlines)
    info = []
    for i, val in enumerate(newlines):
        temp = val.split('\t')
        addr = temp[0]
        svr = temp[1].split(' ')
        type = svr[0]
        name = svr[1]
        line = [addr, type, name]
        info.append(line)
        
    data = []
    for i in range(len(info)):
        item = info[i]
        key = ['id', 'address', 'type', 'name']
        val = [i + 1, item[0], item[1], item[2]]
        
        data.append(dict(zip(key, val)))
        

    json_data = {'code':0, 'msg':'','data':data}
    json_data['count'] = len(data)
    
    json_str = json.dumps(json_data)
    return json_str
        
        
def process_mem(str):
    print(str)
    lines = str.split('\n')
    newlines = [val for i, val in enumerate(lines) if len(val) > 0 and val[0] == ':' ]
    #print(newlines)
    info = []
    for i, val in enumerate(newlines):
        temp = val.split('\t')
        addr = temp[0]
        svr = temp[1].split(' ', 2)
        type = svr[0]
        name = svr[2]
        line = [addr, type, name]
        info.append(line)
        
    data = []
    for i in range(len(info)):
        item = info[i]
        key = ['id', 'address', 'memory', 'name']
        val = [i + 1, item[0], item[1] + 'Kb', item[2]]
        
        data.append(dict(zip(key, val)))
        

    json_data = {'code':0, 'msg':'','data':data}
    json_data['count'] = len(data)
    
    json_str = json.dumps(json_data)
    return json_str
        
    
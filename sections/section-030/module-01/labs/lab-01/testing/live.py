import json,subprocess,time,sys,tempfile,os

def call(*args):
 r=subprocess.run(list(args),text=True,capture_output=True,timeout=20)
 assert r.returncode==0, 'Observation command failed: '+args[0]
 return r.stdout.strip()
def obj(kind,name,ns='starfleet'):
 return json.loads(call('kubectl',*(['-n',ns] if ns else []),'get',kind,name,'-o','json'))
def api(path):
 script='import urllib.request; print(urllib.request.urlopen('+repr('http://prometheus:9090'+path)+',timeout=8).read().decode())'
 return json.loads(call('kubectl','-n','starfleet','exec','shuttle','--','python','-c',script))
def save(data):
 resource={'apiVersion':'v1','kind':'ConfigMap','metadata':{'name':'evidence','namespace':'starfleet'},'data':{'report.json':json.dumps(data,sort_keys=True)}}
 with tempfile.NamedTemporaryFile(mode='w',suffix='.json',delete=False) as f:json.dump(resource,f);path=f.name
 try:call('kubectl','apply','-f',path)
 finally:os.unlink(path)

app=obj('application','mission','argocd')
assert app['status']['sync']['status']=='Synced' and app['status']['health']['status']=='Healthy', 'Application must reconcile and become healthy'
workload=obj('deployment','git-probe');assert workload['spec']['replicas']==2 and workload['status'].get('availableReplicas')==2, 'Git workload must be available'
assert app['status']['sync'].get('revision'), 'Resolved Git revision is absent'
import re
assert re.fullmatch(r'[0-9a-f]{40}', app['status']['sync'].get('revision', '')), 'Revision must be a resolved commit SHA'
kinds = {(r.get('group', ''), r['kind']) for r in app['status'].get('resources', [])}
assert kinds == {('apps', 'Deployment'), ('', 'Service')}, 'The Application must manage only the Deployment and the Service'
assert not app['status'].get('conditions'), 'The Application must have no error conditions'

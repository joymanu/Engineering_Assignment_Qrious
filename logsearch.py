from flask import Flask, jsonify, Response, request
from flask_restful import Api, Resource
import pandas as pd


app = Flask(__name__)
api = Api(app)

class Container(Resource):
    def get(self):
        key = request.args.get('key', default = "", type = str)
        value = request.args.get('value', default = "", type = str)
        data = pd.read_csv('resource.log', delimiter = ",", header=None, names=['Datestamp','ContainerID','Name','Image','Status','CpuPercentage','MemoryPercentage','MemoryLimit','NetIO'], dtype=str)
        if key == 'datestamp':
            data = data[data['Datestamp'].str.contains(str(value))]
        elif key == 'name':
            data = data[data['Name'].str.contains(str(value))]
        res = []
        for index, row in data.iterrows():
            res.append(', '.join(list(row)))
        return jsonify(res)
        

api.add_resource(Container, "/search")

if __name__ == '__main__':
    app.run(debug=True)
import { useState, useEffect } from 'react'
import './App.css'


export default function App(){

    const [data, setData] = useState([]);

    useEffect(() => {

        // fetch('https://z5d5c6sftd.execute-api.us-east-2.amazonaws.com/default')
        fetch('https://2dh9rhdhy0.execute-api.us-east-2.amazonaws.com/default')
            .then(response => response.json())
            .then(data => setData(data))
            .catch(error => console.error('Error fetching data:', error));
    }, []); // The empty array ensures this effect runs only once

    return (
      <div>
        {data.result}
      </div>
    );
}
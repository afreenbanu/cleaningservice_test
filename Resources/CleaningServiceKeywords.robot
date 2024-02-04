*** Settings ***
Library     RequestsLibrary
Library     Process

*** Variables ***
${cleaning_service_url}     http://localhost:8080/v1/cleaning-sessions
${size_of_room}             [5,5]
${size_of_room_invalid}     [0, 0]
${all_patches}              [4, 4],[4, 3], [4, 2], [4, 1], [4, 0], [3, 4],[3, 3], [3, 2], [3, 1], [3, 0], [2, 4],[2, 3], [2, 2], [2, 1], [2, 0], [1, 4],[1, 3], [1, 2], [1, 1], [1, 0], [0, 4],[0, 3], [0, 2], [0, 1], [0, 0]

*** Keywords ***

Construct request header
    ${my_headers}=     create dictionary     content-type=application/json
    Set suite variable      ${my_headers}

cleaning service is up and running
     ${response}=      GET     ${cleaning_service_url}    headers=${my_headers}    expected_status=any
     should be equal as strings    ${response.status_code}      405

I send cleaning request with no input payload
     [Arguments]     ${coords}=[0, 0]     ${patches}=[0, 0]    ${instructions}=${empty}

     ${my_headers}=     create dictionary     content-type=application/json

     ${response}=       POST    ${cleaning_service_url}     data=${empty}     headers=${my_headers}     expected_status=any
     
     Set suite variable     ${response}

Service should return valid response code
     [Arguments]     ${expected_response_code}
     should be equal as strings     ${response.status_code}      ${expected_response_code}

Service response should contain correct message
     [Arguments]       ${message}
     should start with     ${response.json()['message']}    ${message}

I send cleaning request with given payload
    [Arguments]    ${room_size}=[0, 0]      ${coords}=[0, 0]     ${patches}=[0, 0]    ${instructions}=${empty}

     ${my_payload}=     set variable    {"roomSize": ${room_size}, "coords": ${coords}, "patches": [${patches}], "instructions": "${instructions}"}
     ${my_headers}=     create dictionary     content-type=application/json

     ${response}=       POST    ${cleaning_service_url}     data=${my_payload}     headers=${my_headers}     expected_status=any
     
     Set suite variable     ${response}

Service should return hoover coords at
     [Arguments]      ${expected_coords}
     ${actual_coords}       convert to string     ${response.json()['coords']}
     should be equal as strings     ${actual_coords}    ${expected_coords}

Number of cleaned patches should be
     [Arguments]     ${expected_cleaned_patches}
     should be equal as integers     ${response.json()['patches']}    ${expected_cleaned_patches}
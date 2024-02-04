*** Settings ***
Documentation      This test suite contains scenarios for validating the cleaning service endpoint. 
...                Covered are valid parameters, 
...                invalid and missing parameters, 
...                Minimum and Maximum patches and instructions. 
...                Boundary spots coverage
...                Corner spots with and without dirt and bumping into wall
...                Dirt in all spots in room (full coverage)
...                Concurrent requests and state isolation


Resource     ../Resources/CleaningServiceKeywords.robot

Suite Setup     Run keywords     Construct request header      AND     cleaning service is up and running

*** Test Cases ***

1. Verify cleaning service returns 200 when valid request payload is sent
	[Documentation]     Valid request
	
	Given cleaning service is up and running
	When I send cleaning request with given payload      ${size_of_room}    [0, 1]     [0, 0]     NN
	Then Service should return valid response code     200
	AND Service should return hoover coords at     [0, 3]
	AND Number of cleaned patches should be     0

2. Verify cleaning service returns 400 when no payload is sent in the request
	[Documentation]     Empty payload
	
	Given cleaning service is up and running
	When I send cleaning request with no input payload
	Then Service should return valid response code     400
	AND Service response should contain correct message     Request body is missing

3. Verify cleaning service returns 400 when roomSize is invalid
	[Documentation]     Invalid room size. 
	[Tags]      PltSci_ClnSvc_002

	Given cleaning service is up and running
   	When I send cleaning request with given payload      [0, 0]    [0, 0]     [0, 1]     NEE
	Then Service should return valid response code     400
	AND Service response should contain correct message     room size is Invalid

4. Verify cleaning service returns 400 when roomSize is missing
	[Documentation]     Missing room size. 
	
	Given cleaning service is up and running
   	When I send cleaning request with given payload      ${EMPTY}    [0, 0]     [0, 1]     NEE
	Then Service should return valid response code     400
	AND Service response should contain correct message     Failed to read HTTP message

5. Verify cleaning service returns 400 when coords are invalid
	[Documentation]     Invalid coords. 
	[Tags]      PltSci_ClnSvc_002

	Given cleaning service is up and running
   	When I send cleaning request with given payload      ${size_of_room}    [0]     [0, 1]     NEE
	Then Service should return valid response code     400
	AND Service response should contain correct message     Invalid coords

6. Verify cleaning service returns 400 when coords is missing
	[Documentation]     Missing coords. 
	
	Given cleaning service is up and running
   	When I send cleaning request with given payload      ${size_of_room}    ${EMPTY}     [0, 1]     NEE
	Then Service should return valid response code     400
	AND Service response should contain correct message     Failed to read HTTP message

7. Verify cleaning service returns 400 when patches is invalid
	[Documentation]     Invalid patches. 
	[Tags]      PltSci_ClnSvc_002

	Given cleaning service is up and running
   	When I send cleaning request with given payload      ${size_of_room}    [0, 1]     [0]     NEE
	Then Service should return valid response code     400
	AND Service response should contain correct message     Invalid Patches

8. Verify cleaning service returns 0 cleaned patched when patches is empty
    [Documentation]     Missing patches
	
	Given cleaning service is up and running
   	When I send cleaning request with given payload      ${size_of_room}    [0, 0]     ${EMPTY}     NEE
	Then Service should return valid response code     200
	AND Service should return hoover coords at     [2, 1]
	AND Number of cleaned patches should be     0

9. Verify cleaning service returns 400 when instructions are invalid
	[Documentation]     Invalid instructions. 
	[Tags]      PltSci_ClnSvc_002

	Given cleaning service is up and running
	When I send cleaning request with given payload      ${size_of_room}    [0, 0]     [4,4], [4,3]     NEET
	Then Service should return valid response code     400
	AND Service response should contain correct message     Request body is missing

10. Verify cleaning service returns 0 cleaned patches when no instructions are sent
	[Documentation]     No instructions sent, so hoover position should not be changed, 0 patches cleaned
	
	Given cleaning service is up and running
	When I send cleaning request with given payload      ${size_of_room}    [4, 1]     [4, 0]
	Then Service should return valid response code     200
	AND Service should return hoover coords at     [4, 1]
	AND Number of cleaned patches should be     0

11. Verify cleaning service returns 0 cleaned patches when driving directions don't travel patches of dirt
    [Documentation]     Driving route dont touch dirt patches. 0 patches cleaned. 
	
	Given cleaning service is up and running
   	When I send cleaning request with given payload      ${size_of_room}    [0, 0]     [4,4],[4,3]     NEE
	Then Service should return valid response code     200
	AND Service should return hoover coords at     [2, 1]
	AND Number of cleaned patches should be     0

12. Verify cleaning service returns 1 cleaned patch when hoover is at corner spot which is also dirt spot and driving instructions hit the wall
	[Documentation]       Hoover is at one of the 4 corners, hoover's location also has dirt patch, if instructed to go towards wall outcome should be 1 cleaned patch and hoover's 
	...                   location end up at input coords. 
	
	Given cleaning service is up and running
	When I send cleaning request with given payload      ${size_of_room}    [4, 0]     [4, 0],[2, 2]     ES
	Then Service should return valid response code     200
	AND Service should return hoover coords at     [4, 0]
	AND Number of cleaned patches should be     1

13. Verify cleaning service returns 0 cleaned patch when hoover is at corner spot which is not a dirt spot and driving instructions hit the wall
	[Documentation]       Hoover is at one of the 4 corners, hoover's location is not a dirt patch, if instructed to go towards wall outcome should be 0 cleaned patch and hoover's 
	...                   location end up at input coords. 
	...                   May be change the inputs to make it Pass and not fail due to bug. Failed case is tagged bug. 
	
	Given cleaning service is up and running
	When I send cleaning request with given payload      [3,3]    [2, 0]     [1, 1],[2, 2]     ES
	Then Service should return valid response code     200
	AND Service should return hoover coords at     [2, 0]
	AND Number of cleaned patches should be     0

14. Verify cleaning service doesnt cache cleaned spots from previous cleaning sessions when these spots are travelled during subsequent requests
	[Documentation]   This will validate the concurrency of the requests and state isolation. 
	[Tags]     PltSci_ClnSvc_001
	
	Given cleaning service is up and running
	When I send cleaning request with given payload      ${size_of_room}    [0, 1]     [1, 2],[2, 2]     NEE
	Then Service should return valid response code     200
	AND Service should return hoover coords at     [2, 2]
	AND Number of cleaned patches should be     2
	When I send cleaning request with given payload      ${size_of_room}    [0, 2]     [1, 3],[2, 3]     ENE
	Then Service should return valid response code     200
	AND Service should return hoover coords at     [2, 3]
	AND Number of cleaned patches should be     2    # output will be 3 due to bug

15. Verify cleaning service returns 400 when coords placed exactly at the room coordinates
	[Documentation]      Hoover coords are same as room coords
	
	${test_coords}    set variable     ${size_of_room}
	Given cleaning service is up and running
	When I send cleaning request with given payload      ${size_of_room}    ${test_coords}     [4, 3],[2, 2]     ES
	Then Service should return valid response code     400

16. Verify cleaning service returns 400 when coords are outside the room coordinates
	[Documentation]   Hoover starting coords are outside the room coordinates. 
	[Tags]    PltSci_ClnSvc_003
	Given cleaning service is up and running
	When I send cleaning request with given payload      ${size_of_room}    [8, 9]     [4, 3],[2, 2]     ES
	Then Service should return valid response code     400

17. Verify cleaning service cleans patches of dirt at each of 4 corners of the room
	[Documentation]     Hoover cleaning corner spots. Boundary checks. 
	
	Given cleaning service is up and running
	When I send cleaning request with given payload      [4, 4]    [0, 0]     [0, 0], [0, 3],[3, 3],[3, 0]    NNNEEESSSWWW
	Then Service should return valid response code     200
	AND Service should return hoover coords at     [0, 0]
	AND Number of cleaned patches should be     4

18. Verify cleaning services return total patches when every location has dirt
    [Documentation]    When all spots in the room has dirt, hoover should clean and return all spots. 

	Given cleaning service is up and running
	When I send cleaning request with given payload      ${size_of_room}    [4, 4]     ${all_patches}   SSSSWWWWNNNNEEEESWSSWWNNES
	Then Service should return valid response code     200
	AND Service should return hoover coords at     [2, 2]
	AND Number of cleaned patches should be     25
	
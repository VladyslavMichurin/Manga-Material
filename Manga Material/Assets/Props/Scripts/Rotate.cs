using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Rotate : MonoBehaviour
{
    public List<Transform> objToRotate;

    public enum Direction { Right, Left }
    public Direction direction;

    [Range(0f, 30f)]
    public float speed = 10;

    private void FixedUpdate()
    {
        foreach (Transform t in objToRotate)
        {
            if (direction == Direction.Right)
            {
                t.RotateAround(t.transform.position, Vector3.up, -Time.deltaTime * speed);
            }
            else if(direction == Direction.Left)
            {
                t.RotateAround(t.transform.position, Vector3.up, Time.deltaTime * speed);
            }
        }    
    }
}

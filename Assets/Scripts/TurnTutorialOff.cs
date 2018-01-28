using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class TurnTutorialOff : MonoBehaviour {

    public GameObject textObj;

    // Update is called once per frame
    void Update() {
        if (Input.GetKeyDown(KeyCode.Space)) {
            textObj.SetActive(false);
        }
	}
}

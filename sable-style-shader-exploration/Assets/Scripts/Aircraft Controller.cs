using UnityEngine;
#if ENABLE_INPUT_SYSTEM
using UnityEngine.InputSystem;
#endif

public class AircraftController : MonoBehaviour
{
    [Header("Movement")]
    public float forwardSpeed = 12f;
    public float boostSpeed = 20f;
    public float acceleration = 6f;
    public float deceleration = 8f;

    [Header("Steering")]
    public float pitchSpeed = 55f;
    public float yawSpeed = 75f;
    public float minPitch = -35f;
    public float maxPitch = 35f;

    [Header("Visuals")]
    public Transform visualModel;
    public Vector3 visualRotationOffset;

    private float currentForwardSpeed;
    private float yawAngle;
    private float pitchAngle;

    void Awake()
    {
        Vector3 currentEuler = transform.rotation.eulerAngles;
        yawAngle = currentEuler.y;
        pitchAngle = Mathf.Clamp(NormalizeAngle(currentEuler.x), minPitch, maxPitch);
        ApplyRotation();
    }

    void Update()
    {
        HandleRotation();
        HandleMovement();
        ApplyVisualRotationOffset();
    }

    void HandleRotation()
    {
        float pitchInput = GetPitchInput();
        float yawInput = GetYawInput();

        pitchAngle = Mathf.Clamp(pitchAngle + pitchInput * pitchSpeed * Time.deltaTime, minPitch, maxPitch);
        yawAngle += yawInput * yawSpeed * Time.deltaTime;

        ApplyRotation();
    }

    void HandleMovement()
    {
        float targetSpeed = IsPressed(KeyCode.V) ? (IsPressed(KeyCode.LeftShift) ? boostSpeed : forwardSpeed) : 0f;
        float changeRate = targetSpeed > currentForwardSpeed ? acceleration : deceleration;
        currentForwardSpeed = Mathf.MoveTowards(currentForwardSpeed, targetSpeed, changeRate * Time.deltaTime);

        transform.position += transform.forward * currentForwardSpeed * Time.deltaTime;
    }

    void ApplyRotation()
    {
        transform.rotation = Quaternion.Euler(pitchAngle, yawAngle, 0f);
    }

    void ApplyVisualRotationOffset()
    {
        if (visualModel == null)
            return;

        visualModel.localRotation = Quaternion.Euler(visualRotationOffset);
    }

    float GetPitchInput()
    {
#if ENABLE_INPUT_SYSTEM
        return GetAxisFromKeys(Key.W, Key.S);
#else
        float value = 0f;
        if (Input.GetKey(KeyCode.W))
            value += 1f;
        if (Input.GetKey(KeyCode.S))
            value -= 1f;
        return value;
#endif
    }

    float GetYawInput()
    {
#if ENABLE_INPUT_SYSTEM
        return GetAxisFromKeys(Key.D, Key.A);
#else
        float value = 0f;
        if (Input.GetKey(KeyCode.D))
            value += 1f;
        if (Input.GetKey(KeyCode.A))
            value -= 1f;
        return value;
#endif
    }

    bool IsPressed(KeyCode legacyKey)
    {
#if ENABLE_INPUT_SYSTEM
        Keyboard keyboard = Keyboard.current;
        if (keyboard == null)
            return false;

        if (legacyKey == KeyCode.LeftShift)
            return keyboard.leftShiftKey.isPressed;
        if (legacyKey == KeyCode.V)
            return keyboard.vKey.isPressed;

        return false;
#else
        return Input.GetKey(legacyKey);
#endif
    }

    static float NormalizeAngle(float angle)
    {
        while (angle > 180f)
            angle -= 360f;
        while (angle < -180f)
            angle += 360f;
        return angle;
    }

#if ENABLE_INPUT_SYSTEM
    static float GetAxisFromKeys(Key positive, Key negative)
    {
        Keyboard keyboard = Keyboard.current;
        if (keyboard == null)
            return 0f;

        float value = 0f;
        if (keyboard[positive].isPressed)
            value += 1f;
        if (keyboard[negative].isPressed)
            value -= 1f;
        return value;
    }
#endif
}

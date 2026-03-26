using UnityEngine;

public class CameraFollow : MonoBehaviour
{
    public Transform target;
    public Transform focusTarget;

    [Header("Follow Framing")]
    public Vector3 followOffset = new Vector3(-3.5f, 2.6f, -8.5f);
    public Vector3 lookOffset = new Vector3(-1.25f, 1.3f, 12f);

    [Header("Smoothing")]
    public float positionSmoothTime = 0.2f;
    public float rotationSmoothSpeed = 6f;

    [Header("Behavior")]
    public bool autoFindAircraft = true;
    public bool followRoll = false;

    private Vector3 currentVelocity;
    private bool hasSnappedToTarget;

    void Awake()
    {
        TryAssignTarget();
    }

    void LateUpdate()
    {
        if (!TryAssignTarget())
            return;

        Vector3 focusPoint = GetFocusPoint();
        Quaternion chaseRotation = GetChaseRotation();
        Vector3 desiredPos = focusPoint + chaseRotation * followOffset;

        if (!hasSnappedToTarget)
        {
            transform.position = desiredPos;
        }
        else
        {
            transform.position = Vector3.SmoothDamp(transform.position, desiredPos, ref currentVelocity, positionSmoothTime);
        }

        Vector3 lookPoint = focusPoint + chaseRotation * lookOffset;
        Quaternion desiredRotation = Quaternion.LookRotation(lookPoint - transform.position, Vector3.up);

        if (!hasSnappedToTarget)
        {
            transform.rotation = desiredRotation;
            hasSnappedToTarget = true;
        }
        else
        {
            transform.rotation = Quaternion.Slerp(transform.rotation, desiredRotation, rotationSmoothSpeed * Time.deltaTime);
        }
    }

    bool TryAssignTarget()
    {
        if (target != null)
        {
            if (focusTarget == null)
            {
                AircraftController targetAircraft = target.GetComponent<AircraftController>();
                if (targetAircraft != null)
                    focusTarget = targetAircraft.visualModel != null ? targetAircraft.visualModel : targetAircraft.transform;
            }
            return true;
        }

        if (!autoFindAircraft)
            return false;

        AircraftController foundAircraft = FindObjectOfType<AircraftController>();
        if (foundAircraft == null)
            return false;

        target = foundAircraft.transform;
        if (focusTarget == null)
            focusTarget = foundAircraft.visualModel != null ? foundAircraft.visualModel : foundAircraft.transform;
        currentVelocity = Vector3.zero;
        hasSnappedToTarget = false;
        return true;
    }

    Vector3 GetFocusPoint()
    {
        Transform activeFocus = focusTarget != null ? focusTarget : target;
        if (activeFocus == null)
            return transform.position;

        return activeFocus.position;
    }

    Quaternion GetChaseRotation()
    {
        if (followRoll)
            return target.rotation;

        Vector3 flattenedForward = Vector3.ProjectOnPlane(target.forward, Vector3.up);
        if (flattenedForward.sqrMagnitude < 0.0001f)
            flattenedForward = Vector3.ProjectOnPlane(target.up, Vector3.up);
        if (flattenedForward.sqrMagnitude < 0.0001f)
            flattenedForward = transform.forward;

        return Quaternion.LookRotation(flattenedForward.normalized, Vector3.up);
    }
}
